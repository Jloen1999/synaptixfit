import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/enums/device_permission.dart';
import 'package:synaptixfit/domain/use_cases/profile/open_permission_settings_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/discard_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_run_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/is_location_service_enabled_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/list_run_workouts_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/load_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_run_recording_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/track_run_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/run_recorder/bloc/run_recorder_bloc.dart';

/// Grabar una carrera: empezar, puntos, pausa (segmento nuevo), guía de pasos,
/// guardado en el teléfono y terminar (ADR 0037).
void main() {
  late DateTime now;
  late _Store store;
  late _Tracker tracker;
  late _Finish finish;

  const texts = RunNotificationTexts(
    title: 'Grabando tu carrera',
    channelName: 'Carrera en curso',
    body: _body,
  );

  RunRecorderBloc build({List<RunWorkout> workouts = const []}) =>
      RunRecorderBloc(
        load: _Load(store),
        save: _Save(store),
        discard: _Discard(store),
        finish: finish,
        listWorkouts: _ListWorkouts(workouts),
        serviceEnabled: _ServiceEnabled(),
        track: tracker,
        openSettings: _OpenSettings(),
        clock: () => now,
      );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    now = DateTime(2026, 11, 7, 18);
    store = _Store();
    tracker = _Tracker();
    finish = _Finish();
  });

  RunFix fix(double meters, int second) => RunFix(
    latitude: 40 + meters / 111195.08,
    longitude: -3.7,
    accuracy: 5,
    time: DateTime(2026, 11, 7, 18).add(Duration(seconds: second)),
  );

  test('graba, pausa con segmento nuevo y guarda en el teléfono', () async {
    final bloc = build()..add(const RunRecorderEvent.started(texts: texts));
    await settle();
    expect(bloc.state.phase, RunPhase.ready);
    bloc.add(const RunRecorderEvent.recordingStarted());
    await settle();
    expect(bloc.state.phase, RunPhase.recording);
    expect(store.current?.clientKey, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(tracker.watching, isTrue);

    for (var s = 0; s <= 20; s++) {
      tracker.emit(fix(3.0 * s, s));
    }
    await settle();
    expect(bloc.state.meters, closeTo(60, 3));
    // Cada 5 puntos se guarda: si se cierra la app no se pierde nada.
    expect(store.current!.points.length, greaterThanOrEqualTo(20));

    now = now.add(const Duration(seconds: 30));
    bloc.add(const RunRecorderEvent.pauseRequested());
    await settle();
    expect(bloc.state.phase, RunPhase.paused);
    tracker.emit(fix(500, 40));
    await settle();
    expect(
      bloc.state.recording!.points.length,
      21,
      reason: 'en pausa no cuenta',
    );

    now = now.add(const Duration(seconds: 60));
    bloc.add(const RunRecorderEvent.resumeRequested());
    await settle();
    expect(bloc.state.recording!.segment, 1);
    expect(bloc.state.recording!.pausedSeconds, 60);
    await bloc.close();
  });

  test('con un entreno, vibra al cambiar de paso', () async {
    const workout = RunWorkout(
      id: 'w1',
      name: 'Series',
      groups: [
        RunStepGroup(
          steps: [
            RunStep(
              type: RunStepType.warmup,
              measure: RunMeasure.time,
              value: 60,
            ),
            RunStep(
              type: RunStepType.run,
              measure: RunMeasure.distance,
              value: 400,
            ),
          ],
        ),
      ],
    );
    final bloc = build(workouts: [workout])
      ..add(const RunRecorderEvent.started(workoutId: 'w1', texts: texts));
    await settle();
    await settle();
    expect(bloc.state.guide?.current?.type, RunStepType.warmup);
    bloc.add(const RunRecorderEvent.recordingStarted());
    await settle();
    now = now.add(const Duration(seconds: 61));
    bloc.add(const RunRecorderEvent.ticked());
    await settle();
    expect(bloc.state.guide?.current?.type, RunStepType.run);
    expect(bloc.state.stepChanges, 1);
    expect(tracker.vibrations, 1);
    expect(tracker.notifications.last, contains('Correr'));
    await bloc.close();
  });

  test(
    'al terminar se manda con el esfuerzo; salir a mitad la deja en pausa',
    () async {
      final bloc = build()..add(const RunRecorderEvent.started(texts: texts));
      await settle();
      bloc.add(const RunRecorderEvent.recordingStarted());
      await settle();
      tracker.emit(fix(0, 0));
      await settle();
      bloc.add(const RunRecorderEvent.finishRequested(7));
      await settle();
      await settle();
      expect(finish.effort, 7);
      expect(bloc.state.phase, RunPhase.queued);
      expect(tracker.watching, isFalse);
      await bloc.close();

      final again = build()..add(const RunRecorderEvent.started(texts: texts));
      await settle();
      again.add(const RunRecorderEvent.recordingStarted());
      await settle();
      await again.close();
      expect(store.current?.pausedAt, isNotNull);
    },
  );
}

String _body(double meters, int seconds, RunStep? step) =>
    '${meters.round()} m · $seconds s${step == null ? '' : ' · ${step.type == RunStepType.run ? 'Correr' : 'Calentar'}'}';

class _Store {
  RunRecording? current;
}

class _Load implements LoadRunRecordingUseCaseContract {
  _Load(this._store);
  final _Store _store;
  @override
  Future<AppResult<RunRecording?>> call() async => Success(_store.current);
}

class _Save implements SaveRunRecordingUseCaseContract {
  _Save(this._store);
  final _Store _store;
  @override
  Future<AppResult<Unit>> call(RunRecording recording) async {
    _store.current = recording;
    return const Success(unit);
  }
}

class _Discard implements DiscardRunRecordingUseCaseContract {
  _Discard(this._store);
  final _Store _store;
  @override
  Future<AppResult<Unit>> call() async {
    _store.current = null;
    return const Success(unit);
  }
}

class _Finish implements FinishRunUseCaseContract {
  int? effort;
  @override
  Future<AppResult<RunSaved?>> call(
    RunRecording recording, {
    required int effort,
  }) async {
    this.effort = effort;
    return const Success(null);
  }
}

class _ListWorkouts implements ListRunWorkoutsUseCaseContract {
  _ListWorkouts(this._workouts);
  final List<RunWorkout> _workouts;
  @override
  Future<AppResult<List<RunWorkout>>> call() async => Success(_workouts);
}

class _ServiceEnabled implements IsLocationServiceEnabledUseCaseContract {
  @override
  Future<AppResult<bool>> call() async => const Success(true);
}

class _Tracker implements TrackRunUseCaseContract {
  StreamController<AppResult<RunFix>>? _controller;
  int vibrations = 0;
  final notifications = <String>[];

  bool get watching => _controller?.hasListener ?? false;

  void emit(RunFix fix) => _controller?.add(Success(fix));

  @override
  bool get supported => true;

  @override
  Stream<AppResult<RunFix>> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  }) {
    _controller = StreamController<AppResult<RunFix>>();
    return _controller!.stream;
  }

  @override
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  }) async => notifications.add(text);

  @override
  Future<void> vibrate() async => vibrations++;
}

class _OpenSettings implements OpenPermissionSettingsUseCaseContract {
  @override
  Future<AppResult<Unit>> call(DevicePermission permission) async =>
      const Success(unit);
}
