import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../../domain/models/training/run_live.dart';
import '../../../../../domain/enums/device_permission.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../../domain/use_cases/profile/open_permission_settings_use_case.dart';
import '../../../../../domain/use_cases/training/discard_run_recording_use_case.dart';
import '../../../../../domain/use_cases/training/finish_run_use_case.dart';
import '../../../../../domain/use_cases/training/is_location_service_enabled_use_case.dart';
import '../../../../../domain/use_cases/training/list_run_workouts_use_case.dart';
import '../../../../../domain/use_cases/training/load_run_recording_use_case.dart';
import '../../../../../domain/use_cases/training/save_run_recording_use_case.dart';
import '../../../../../domain/use_cases/training/track_run_use_case.dart';

part 'run_recorder_bloc.freezed.dart';
part 'run_recorder_event.dart';
part 'run_recorder_state.dart';

/// Textos del aviso fijo mientras se graba. Los pone la pantalla (en su
/// idioma) porque con la pantalla apagada no se pinta nada y el bloc sigue.
class RunNotificationTexts {
  const RunNotificationTexts({
    required this.title,
    required this.channelName,
    required this.body,
  });

  final String title;
  final String channelName;

  /// «3,2 km · 18:40» y, con un entreno, el paso actual.
  final String Function(double meters, int seconds, RunStep? step) body;
}

/// Grabar una carrera con el GPS (ADR 0037): empezar, pausar, reanudar y
/// terminar. Cada pocos puntos se guarda en el teléfono (no se pierde nada si
/// se cierra la app); al terminar va a la cola y se sube sin duplicarse. Las
/// cifras en directo son orientativas: las que quedan las calcula el servidor.
/// Con un entreno de carrera guía paso a paso y vibra al cambiar de paso.
class RunRecorderBloc extends Bloc<RunRecorderEvent, RunRecorderState> {
  RunRecorderBloc({
    required this._load,
    required this._save,
    required this._discard,
    required this._finish,
    required this._listWorkouts,
    required this._serviceEnabled,
    required this._track,
    required this._openSettings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const RunRecorderState()) {
    on<RunRecorderStarted>(_onStarted);
    on<RunRecorderKindChanged>((e, emit) => emit(state.copyWith(kind: e.kind)));
    on<RunRecorderRecordingStarted>(_onRecordingStarted);
    on<RunRecorderFixReceived>(_onFix);
    on<RunRecorderTicked>(_onTick);
    on<RunRecorderPauseRequested>(_onPause);
    on<RunRecorderResumeRequested>(_onResume);
    on<RunRecorderFinishRequested>(_onFinish);
    on<RunRecorderDiscardRequested>(_onDiscard);
    on<RunRecorderPersistRequested>((_, emit) => _persist());
    on<RunRecorderBatterySettingsOpened>((_, _) async {
      await _openSettings(DevicePermission.location);
    });
    on<RunRecorderGpsFailed>(
      (e, emit) => emit(state.copyWith(gpsError: e.error)),
    );
  }

  final LoadRunRecordingUseCaseContract _load;
  final SaveRunRecordingUseCaseContract _save;
  final DiscardRunRecordingUseCaseContract _discard;
  final FinishRunUseCaseContract _finish;
  final ListRunWorkoutsUseCaseContract _listWorkouts;
  final IsLocationServiceEnabledUseCaseContract _serviceEnabled;
  final TrackRunUseCaseContract _track;
  final OpenPermissionSettingsUseCaseContract _openSettings;
  final DateTime Function() _clock;

  StreamSubscription<Object?>? _gps;
  Timer? _ticker;
  RunNotificationTexts? _texts;
  int _unsaved = 0;

  /// Cada cuántos puntos nuevos se guarda la carrera en el teléfono.
  static const _saveEvery = 5;

  /// Sin puntos durante este tiempo, se avisa de que se busca señal.
  static const _signalLostAfter = Duration(seconds: 15);

  /// El aviso fijo se pone al día cada pocos segundos (no cada segundo, para
  /// no gastar batería).
  static const _notifyEverySeconds = 5;

  Future<void> _onStarted(
    RunRecorderStarted e,
    Emitter<RunRecorderState> emit,
  ) async {
    _texts = e.texts;
    if (!_track.supported) {
      emit(state.copyWith(phase: RunPhase.unsupported));
      return;
    }
    RunWorkout? workout;
    final current = (await _load()).valueOrNull;
    final workoutId = current?.workoutId ?? e.workoutId;
    if (workoutId != null) {
      workout = (await _listWorkouts()).valueOrNull
          ?.where((w) => w.id == workoutId)
          .firstOrNull;
    }
    if (current != null && !current.finished) {
      // La app se cerró grabando: el GPS se paró entonces, así que ese rato
      // cuenta como pausa y se sigue con «Seguir» (o se termina).
      final resumed = current.pausedAt != null
          ? current
          : current.copyWith(pausedAt: _lastPointTime(current));
      emit(
        state.copyWith(
          phase: RunPhase.paused,
          recording: resumed,
          kind: resumed.kind,
          workout: workout,
          eventId: resumed.plannedBlockId,
          meters: RunLiveStats.meters(resumed.points),
          activeSeconds: RunLiveStats.activeSeconds(resumed, _clock()),
          guide: _guideFor(workout),
        ),
      );
      _advanceGuide(emit, announce: false);
      // El GPS no se enciende hasta pulsar «Seguir».
      await _save(resumed);
      return;
    }
    emit(
      state.copyWith(
        phase: RunPhase.ready,
        workout: workout,
        eventId: e.eventId,
        guide: _guideFor(workout),
      ),
    );
  }

  Future<void> _onRecordingStarted(
    RunRecorderRecordingStarted e,
    Emitter<RunRecorderState> emit,
  ) async {
    if (state.phase != RunPhase.ready) return;
    final enabled = (await _serviceEnabled()).valueOrNull ?? true;
    if (!enabled) {
      emit(state.copyWith(locationOff: true));
      emit(state.copyWith(locationOff: false));
      return;
    }
    final recording = RunRecording(
      clientKey: _uuidV4(),
      kind: state.kind,
      startedAt: _clock(),
      workoutId: state.workout?.id,
      plannedBlockId: state.eventId,
    );
    await _save(recording);
    emit(
      state.copyWith(
        phase: RunPhase.recording,
        recording: recording,
        meters: 0,
        activeSeconds: 0,
        lastFixAt: _clock(),
      ),
    );
    _subscribe();
  }

  void _subscribe() {
    final texts = _texts;
    _gps ??= _track
        .watch(
          notificationTitle: texts?.title ?? '',
          notificationText:
              texts?.body(state.meters, state.activeSeconds, null) ?? '',
          channelName: texts?.channelName ?? '',
        )
        .listen((result) {
          if (isClosed) return;
          switch (result) {
            case Success(:final value):
              add(RunRecorderEvent.fixReceived(value));
            case Failure(:final error):
              add(RunRecorderEvent.gpsFailed(error));
          }
        });
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const RunRecorderEvent.ticked());
    });
  }

  Future<void> _onFix(
    RunRecorderFixReceived e,
    Emitter<RunRecorderState> emit,
  ) async {
    final r = state.recording;
    if (r == null || state.phase != RunPhase.recording) return;
    final fix = e.fix;
    final offset = fix.time.difference(r.startedAt).inMilliseconds / 1000;
    if (offset < 0) return;
    final points = [
      ...r.points,
      RunTrackPoint(
        latitude: fix.latitude,
        longitude: fix.longitude,
        altitude: fix.altitude,
        accuracy: fix.accuracy,
        offsetSeconds: offset,
        segment: r.segment,
      ),
    ];
    final next = r.copyWith(points: points);
    emit(
      state.copyWith(
        recording: next,
        meters: RunLiveStats.meters(points),
        lastFixAt: _clock(),
        weakSignal: fix.accuracy > RunLiveStats.maxAccuracyMeters,
        gpsError: null,
      ),
    );
    if (++_unsaved >= _saveEvery) await _persist();
  }

  Future<void> _onTick(
    RunRecorderTicked e,
    Emitter<RunRecorderState> emit,
  ) async {
    final r = state.recording;
    if (r == null) return;
    final now = _clock();
    final seconds = RunLiveStats.activeSeconds(r, now);
    final lost =
        state.phase == RunPhase.recording &&
        state.lastFixAt != null &&
        now.difference(state.lastFixAt!) > _signalLostAfter;
    emit(state.copyWith(activeSeconds: seconds, signalLost: lost));
    final changed = _advanceGuide(emit, announce: true);
    if (state.phase == RunPhase.recording &&
        (changed || seconds % _notifyEverySeconds == 0)) {
      await _notify();
    }
  }

  /// Pasa los pasos cumplidos; si cambió, vibra (y lo anuncia la pantalla).
  bool _advanceGuide(Emitter<RunRecorderState> emit, {required bool announce}) {
    final guide = state.guide;
    if (guide == null || guide.finished) return false;
    final next = guide.advance(state.activeSeconds, state.meters);
    if (next.index == guide.index) return false;
    emit(
      state.copyWith(
        guide: next,
        stepChanges: announce ? state.stepChanges + 1 : state.stepChanges,
      ),
    );
    if (announce) unawaited(_track.vibrate());
    return true;
  }

  Future<void> _notify() async {
    final texts = _texts;
    if (texts == null) return;
    await _track.updateNotification(
      title: texts.title,
      text: texts.body(state.meters, state.activeSeconds, state.guide?.current),
      channelName: texts.channelName,
    );
  }

  Future<void> _onPause(
    RunRecorderPauseRequested e,
    Emitter<RunRecorderState> emit,
  ) async {
    final r = state.recording;
    if (r == null || state.phase != RunPhase.recording) return;
    final paused = r.copyWith(pausedAt: _clock());
    emit(state.copyWith(phase: RunPhase.paused, recording: paused));
    await _persist();
  }

  Future<void> _onResume(
    RunRecorderResumeRequested e,
    Emitter<RunRecorderState> emit,
  ) async {
    final r = state.recording;
    final since = r?.pausedAt;
    if (r == null || since == null) return;
    final now = _clock();
    // Un segmento nuevo: lo que se movió en pausa no suma distancia.
    final resumed = r.copyWith(
      pausedAt: null,
      pausedSeconds:
          r.pausedSeconds + math.max(0, now.difference(since).inSeconds),
      segment: r.segment + 1,
    );
    emit(
      state.copyWith(
        phase: RunPhase.recording,
        recording: resumed,
        lastFixAt: now,
      ),
    );
    await _persist();
    _subscribe();
  }

  Future<void> _onFinish(
    RunRecorderFinishRequested e,
    Emitter<RunRecorderState> emit,
  ) async {
    final r = state.recording;
    if (r == null || state.phase == RunPhase.saving) return;
    emit(state.copyWith(phase: RunPhase.saving));
    await _stopTracking();
    final result = await _finish(r, effort: e.effort);
    switch (result) {
      case Success(value: final saved?):
        emit(state.copyWith(phase: RunPhase.saved, saved: saved));
      case Success():
        emit(state.copyWith(phase: RunPhase.queued));
      case Failure(:final error):
        // Rechazada por una regla (muy corta, muy antigua): no se guarda y la
        // pantalla explica por qué y ofrece apuntarla a mano.
        emit(
          state.copyWith(
            phase: RunPhase.rejected,
            recording: null,
            finishError: error,
          ),
        );
    }
  }

  Future<void> _onDiscard(
    RunRecorderDiscardRequested e,
    Emitter<RunRecorderState> emit,
  ) async {
    await _stopTracking();
    await _discard();
    emit(state.copyWith(phase: RunPhase.discarded, recording: null));
  }

  Future<void> _persist() async {
    final r = state.recording;
    if (r == null || r.finished) return;
    _unsaved = 0;
    await _save(r);
  }

  Future<void> _stopTracking() async {
    _ticker?.cancel();
    _ticker = null;
    await _gps?.cancel();
    _gps = null;
  }

  static RunGuide? _guideFor(RunWorkout? workout) {
    final steps = workout?.steps ?? const <RunStep>[];
    return steps.isEmpty ? null : RunGuide(steps: steps);
  }

  static DateTime _lastPointTime(RunRecording r) => r.points.isEmpty
      ? r.startedAt
      : r.startedAt.add(
          Duration(milliseconds: (r.points.last.offsetSeconds * 1000).round()),
        );

  /// UUID v4 para la clave idempotente de la subida.
  static String _uuidV4() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  Future<void> close() async {
    // Salir de la pantalla pausa la carrera: queda guardada y se sigue desde
    // Entreno › Correr («Tienes una carrera sin terminar»).
    final r = state.recording;
    if (r != null && !r.finished && r.pausedAt == null) {
      await _save(r.copyWith(pausedAt: _clock()));
    } else {
      await _persist();
    }
    await _stopTracking();
    return super.close();
  }
}
