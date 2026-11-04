import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/load_suggestion.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/session_adaptation.dart';
import '../../../../../domain/models/training/set_fields.dart';
import '../../../../../domain/use_cases/training/load_pending_sets_use_case.dart';
import '../../../../../domain/use_cases/training/save_pending_sets_use_case.dart';
import '../../../../../domain/use_cases/training/get_last_performance_use_case.dart';
import '../../../../../domain/use_cases/training/get_load_suggestions_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_bookends_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/training/cancel_session_use_case.dart';
import '../../../../../domain/use_cases/training/delete_set_use_case.dart';
import '../../../../../domain/use_cases/training/finish_session_use_case.dart';
import '../../../../../domain/use_cases/training/get_routine_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_adaptation_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_use_case.dart';
import '../../../../../domain/use_cases/training/pause_session_use_case.dart';
import '../../../../../domain/use_cases/training/record_set_use_case.dart';
import '../../../../../domain/use_cases/training/resume_session_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_clock_intro_hidden_use_case.dart';
import '../../../../../domain/use_cases/training/hide_session_clock_intro_use_case.dart';
import '../../../../../domain/models/training/live_session_draft.dart';
import '../../../../../domain/use_cases/training/load_live_session_draft_use_case.dart';
import '../../../../../domain/use_cases/training/save_live_session_draft_use_case.dart';
import '../../training_effect.dart';

part 'live_session_bloc.freezed.dart';
part 'live_session_event.dart';
part 'live_session_state.dart';

/// Sesión en vivo: series, descansos, duración real por ejercicio, cronómetro
/// total y finalización con RPE (experiencia, calorías y sugerencias).
class LiveSessionBloc extends Bloc<LiveSessionEvent, LiveSessionState> {
  LiveSessionBloc({
    required this._getSession,
    required this._getRoutine,
    required this._recordSet,
    required this._deleteSet,
    required this._finish,
    required this._cancel,
    required this._getAccount,
    required this._getLastPerformance,
    required this._getBookends,
    required this._getAdaptation,
    required this._getLoadSuggestions,
    required this._loadPending,
    required this._savePending,
    required this._pauseSession,
    required this._resumeSession,
    required this._getClockIntroHidden,
    required this._hideClockIntro,
    required this._loadDraft,
    required this._saveDraft,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const LiveSessionState()) {
    on<LiveSessionStarted>(_onStarted);
    on<LiveSessionAdaptationDeclined>((_, emit) {
      if (!state.adaptation.adapted) return;
      emit(
        state.copyWith(
          exercises: [
            for (final e in state.exercises)
              e.copyWith(
                parameters: e.parameters.copyWith(
                  sets: state.plannedSetsById[e.id] ?? e.parameters.sets,
                ),
              ),
          ],
          adaptation: const SessionAdaptation(),
        ),
      );
    });
    on<LiveSessionLoadSuggestionToggled>((e, emit) {
      if (!state.loadSuggestions.containsKey(e.plannedExerciseId)) return;
      emit(
        state.copyWith(
          acceptedLoad: e.accepted
              ? {...state.acceptedLoad, e.plannedExerciseId}
              : ({...state.acceptedLoad}..remove(e.plannedExerciseId)),
        ),
      );
    });
    on<LiveSessionTicked>((_, emit) => _recalculate(emit));
    on<LiveSessionResumed>((_, emit) => _recalculate(emit, resumed: true));
    on<LiveSessionExerciseSelected>(
      (e, emit) => emit(state.copyWith(activeExerciseId: e.plannedExerciseId)),
    );
    on<LiveSessionSetRecorded>(_onSetRecorded);
    on<LiveSessionSetDeleted>(_onSetDeleted);
    on<LiveSessionRestStarted>(
      (e, emit) => emit(_withRest(state, e.seconds, from: _clock())),
    );
    on<LiveSessionRestAdjusted>((e, emit) {
      final endsAt = state.restEndsAt;
      if (endsAt == null) return;
      final next = endsAt.add(Duration(seconds: e.deltaSeconds));
      final left = _secondsLeft(next, _clock());
      emit(
        left <= 0
            ? state.copyWith(restRemaining: null, restEndsAt: null)
            : state.copyWith(
                restRemaining: left,
                restEndsAt: next,
                restTotal: math.max(state.restTotal, left),
              ),
      );
    });
    on<LiveSessionRestSkipped>(
      (_, emit) => emit(state.copyWith(restRemaining: null, restEndsAt: null)),
    );
    on<LiveSessionFinishRequested>(_onFinish);
    on<LiveSessionPendingRetried>((_, emit) async {
      await _retryResume(emit);
      await _flushPending(emit);
    });
    on<LiveSessionAbandonRequested>(_onAbandon);
    on<LiveSessionSetTimerStarted>(_onSetTimerStarted);
    on<LiveSessionPauseRequested>(_onPause);
    on<LiveSessionResumeRequested>(_onResume);
    on<LiveSessionExerciseSwapped>(_onExerciseSwapped);
    on<LiveSessionClockExplained>((e, emit) async {
      emit(state.copyWith(explainClock: false));
      // Si no se puede guardar, la próxima vez se vuelve a explicar: no es grave.
      if (e.hideNextTime) await _hideClockIntro();
    });
  }

  final GetSessionUseCaseContract _getSession;
  final GetSessionAdaptationUseCaseContract _getAdaptation;
  final GetLoadSuggestionsUseCaseContract _getLoadSuggestions;
  final GetRoutineUseCaseContract _getRoutine;
  final RecordSetUseCaseContract _recordSet;
  final DeleteSetUseCaseContract _deleteSet;
  final FinishSessionUseCaseContract _finish;
  final CancelSessionUseCaseContract _cancel;
  final GetAccountUseCaseContract _getAccount;
  final GetLastPerformanceUseCaseContract _getLastPerformance;
  final GetSessionBookendsUseCaseContract _getBookends;
  final LoadPendingSetsUseCaseContract _loadPending;
  final SavePendingSetsUseCaseContract _savePending;
  final PauseSessionUseCaseContract _pauseSession;
  final ResumeSessionUseCaseContract _resumeSession;
  final GetSessionClockIntroHiddenUseCaseContract _getClockIntroHidden;
  final HideSessionClockIntroUseCaseContract _hideClockIntro;
  final LoadLiveSessionDraftUseCaseContract _loadDraft;
  final SaveLiveSessionDraftUseCaseContract _saveDraft;
  final DateTime Function() _clock;

  /// Una sesión que lleva menos de esto abierta y sin series se acaba de
  /// empezar: es cuando se explica el cronómetro.
  static const _introSeconds = 120;

  /// Cada cuántos segundos se reintenta subir las series pendientes.
  static const _retrySeconds = 15;

  /// Prefijo del id de las series que solo están en el teléfono.
  static const pendingPrefix = 'pending-';

  static const _maxExerciseSeconds = 14400;
  static const _maxSessionSeconds = 86400;

  Future<void> _onStarted(
    LiveSessionStarted event,
    Emitter<LiveSessionState> emit,
  ) async {
    emit(LiveSessionState(sessionId: event.sessionId));
    final result = await _getSession(event.sessionId);
    final session = result.valueOrNull;
    if (session == null) {
      emit(
        state.copyWith(status: LiveStatus.failure, error: result.errorOrNull),
      );
      return;
    }

    var exercises = const <PlannedExercise>[];
    String? routineName;
    RoutineDay? day;
    final routineId = session.routineId;
    final dayId = session.dayId;
    if (routineId != null && dayId != null) {
      final routine = await _getRoutine(routineId);
      switch (routine) {
        case Success(value: final r):
          routineName = r.name;
          day = r.dayById(dayId);
          exercises = day?.exercises ?? const [];
        case Failure(:final error):
          emit(state.copyWith(status: LiveStatus.failure, error: error));
          return;
      }
    }

    // Regulación cruzada: series de hoy según examen, carga y fatiga (si
    // falla, la sesión sigue tal cual).
    var adaptation = const SessionAdaptation();
    final plannedSets = {for (final e in exercises) e.id: e.parameters.sets};
    if (!session.isCompleted && exercises.isNotEmpty) {
      adaptation =
          (await _getAdaptation(session.id)).valueOrNull ??
          const SessionAdaptation();
      final changed = exercises.any(
        (e) =>
            (adaptation.sets[e.id] ?? e.parameters.sets) != e.parameters.sets,
      );
      if (changed) {
        exercises = [
          for (final e in exercises)
            e.copyWith(
              parameters: e.parameters.copyWith(
                sets: adaptation.sets[e.id] ?? e.parameters.sets,
              ),
            ),
        ];
      } else {
        // Si el redondeo deja todas las series igual, no hay nada que avisar.
        adaptation = const SessionAdaptation();
      }
    }

    // Tiempo activo: las pausas no cuentan (ADR 0030).
    final elapsed = session.isCompleted
        ? session.durationMinutes * 60
        : session.activeSecondsAt(_clock());
    // Series que quedaron sin subir (sin conexión) en una apertura anterior.
    final pending = session.isCompleted
        ? const <SetRecord>[]
        : (await _loadPending(session.id)).valueOrNull ?? const <SetRecord>[];
    emit(
      state.copyWith(
        status: LiveStatus.ready,
        session: _withPending(session, pending),
        pendingSets: pending,
        exercises: exercises,
        adaptation: adaptation,
        plannedSetsById: plannedSets,
        routineName: routineName,
        dayNumber: day?.dayNumber,
        dayName: day?.name,
        elapsedSeconds: elapsed,
        startedAt: session.startedAt,
        countedUntil: _clock(),
        activeExerciseId: _firstUnfinished(session, exercises),
      ),
    );
    if (session.isCompleted) {
      // Terminada en otro sitio (otro dispositivo, la web o dada por
      // abandonada): lo que quedara guardado en este teléfono ya no sirve.
      await _savePending(session.id, const <SetRecord>[]);
      await _saveDraft(session.id, const LiveSessionDraft());
      return;
    }
    // Cronómetro de la serie y cambios de hoy que solo sabe el teléfono: se
    // recuperan aunque la app se cerrara (si no se pueden leer, se empieza sin).
    _restoreDraft(
      emit,
      (await _loadDraft(session.id)).valueOrNull ?? const LiveSessionDraft(),
    );
    if (session.sets.isEmpty &&
        pending.isEmpty &&
        elapsed < _introSeconds &&
        // Si no se puede leer la preferencia, se explica.
        !((await _getClockIntroHidden()).valueOrNull ?? false)) {
      emit(state.copyWith(explainClock: true));
    }
    // Ayudas que no bloquean la sesión: si fallan, simplemente no se muestran.
    final (last, bookends, loads) = await (
      _getLastPerformance(),
      exercises.isEmpty
          ? Future.value(
              const Success<SessionBookends, AppError>(SessionBookends()),
            )
          : _getBookends([for (final e in exercises) e.exerciseId]),
      exercises.isEmpty
          ? Future.value(
              const Success<List<LoadSuggestion>, AppError>(<LoadSuggestion>[]),
            )
          : _getLoadSuggestions(session.id),
    ).wait;
    // Solo las de ejercicios de este día que aún tienen series por hacer.
    // Un ejercicio cambiado hoy no usa la propuesta del de la rutina.
    final ids = {
      for (final e in exercises)
        if (!state.originals.containsKey(e.id)) e.id,
    };
    final loadById = {
      for (final l in loads.valueOrNull ?? const <LoadSuggestion>[])
        if (ids.contains(l.plannedExerciseId)) l.plannedExerciseId: l,
    };
    final lastByExercise = {
      for (final r in last.valueOrNull ?? const <PersonalRecord>[])
        r.exerciseId: r,
    };
    final suggested = bookends.valueOrNull;
    final hasBookends =
        suggested != null &&
        (suggested.warmUp.isNotEmpty || suggested.coolDown.isNotEmpty);
    if (lastByExercise.isEmpty && !hasBookends && loadById.isEmpty) return;
    emit(
      state.copyWith(
        lastPerformance: lastByExercise,
        bookends: hasBookends ? suggested : null,
        loadSuggestions: loadById,
      ),
    );
  }

  /// Primer ejercicio con series pendientes (o el primero).
  String? _firstUnfinished(
    TrainingSession session,
    List<PlannedExercise> exercises,
  ) {
    for (final e in exercises) {
      if (_loggedSets(session, e) < e.parameters.sets) return e.id;
    }
    return exercises.isEmpty ? null : exercises.first.id;
  }

  /// Al completar las series previstas de un ejercicio se pasa solo al
  /// siguiente sin terminar (su cronómetro empieza a contar); si ya no queda
  /// ninguno, nulo (no cuenta ninguno). Una serie fuera del plan deja
  /// [fallback].
  String? _activeAfter(
    TrainingSession session,
    PlannedExercise? recorded, {
    required String? fallback,
  }) {
    if (recorded == null) return fallback;
    if (_loggedSets(session, recorded) < recorded.parameters.sets) {
      return recorded.id;
    }
    for (final e in state.exercises) {
      if (_loggedSets(session, e) < e.parameters.sets) return e.id;
    }
    return null;
  }

  /// Pone el cronómetro, el ejercicio activo y el descanso a la hora del
  /// reloj. Se calcula con instantes (no restando 1 por tic) porque los tics se
  /// retrasan o se paran con la pantalla apagada o la app en segundo plano.
  void _recalculate(Emitter<LiveSessionState> emit, {bool resumed = false}) {
    if (state.status != LiveStatus.ready || state.completed) return;
    final now = _clock();
    final from = state.countedUntil;
    // Sin referencia, o si el reloj del teléfono retrocede, se cuenta desde ya.
    var delta = 0;
    var counted = now;
    if (from != null && !now.isBefore(from)) {
      delta = now.difference(from).inSeconds;
      // Se avanza en segundos enteros para no perder las fracciones entre tics.
      counted = from.add(Duration(seconds: delta));
    }
    final startedAt = state.startedAt;
    final session = state.session;
    final elapsed = session != null
        ? session.activeSecondsAt(now)
        : startedAt == null
        ? state.elapsedSeconds + delta
        : math.max(0, now.difference(startedAt).inSeconds);
    final active = state.activeExerciseId;
    // En pausa no suma el ejercicio activo (pero el reloj de referencia avanza).
    final seconds = active == null || delta == 0 || state.paused
        ? state.exerciseSeconds
        : {
            ...state.exerciseSeconds,
            active: (state.exerciseSeconds[active] ?? 0) + delta,
          };
    final endsAt = state.restEndsAt;
    final left = endsAt == null ? null : _secondsLeft(endsAt, now);
    final restOver = left != null && left <= 0;
    final retryDue =
        resumed ||
        elapsed ~/ _retrySeconds != state.elapsedSeconds ~/ _retrySeconds;
    final owed = state.pendingSets.isNotEmpty || state.resumePendingAt != null;
    if (owed && !state.saving && retryDue) {
      add(const LiveSessionEvent.pendingRetried());
    }
    final since = state.timerSince;
    emit(
      state.copyWith(
        elapsedSeconds: elapsed,
        countedUntil: counted,
        exerciseSeconds: seconds,
        timerSeconds: since == null
            ? state.timerBanked
            : state.timerBanked + math.max(0, now.difference(since).inSeconds),
        restRemaining: restOver ? null : left,
        restEndsAt: restOver ? null : endsAt,
        restFinishedCount: restOver
            ? state.restFinishedCount + 1
            : state.restFinishedCount,
      ),
    );
  }

  /// Segundos que faltan hasta [endsAt], redondeando hacia arriba (con 0,4 s
  /// aún se ve «0:01», como en cualquier cuenta atrás).
  static int _secondsLeft(DateTime endsAt, DateTime now) =>
      (endsAt.difference(now).inMilliseconds / 1000).ceil();

  /// [s] con un descanso de [seconds] que empezó en [from] (sin descanso si
  /// ya habría terminado o dura 0).
  LiveSessionState _withRest(
    LiveSessionState s,
    int seconds, {
    required DateTime from,
  }) {
    final endsAt = from.add(Duration(seconds: seconds));
    final left = _secondsLeft(endsAt, _clock());
    return left <= 0
        ? s.copyWith(restRemaining: null, restEndsAt: null)
        : s.copyWith(
            restRemaining: left,
            restTotal: seconds,
            restEndsAt: endsAt,
          );
  }

  /// Tras apuntar [record] en el instante [at] (subida o pendiente): arranca el
  /// descanso previsto desde ese toque (no desde la respuesta del servidor,
  /// que con mala cobertura tarda) y pasa al ejercicio que toca. Una serie con
  /// repeticiones de menos también descansa. Con [startRest] falso no toca el
  /// descanso (ya lo arrancó una serie posterior).
  LiveSessionState _afterSet(
    LiveSessionState s,
    SetRecord record,
    DateTime at, {
    bool startRest = true,
  }) {
    // El calentamiento no abre descanso ni cambia de ejercicio.
    if (record.warmup) return s;
    final planned = s.exercises
        .where((e) => e.id == record.plannedExerciseId)
        .firstOrNull;
    final rest = startRest ? planned?.parameters.restSeconds : null;
    final next = rest == null ? s : _withRest(s, rest, from: at);
    final session = next.session;
    if (session == null) return next;
    return next.copyWith(
      activeExerciseId: _activeAfter(
        session,
        planned,
        fallback: record.plannedExerciseId ?? s.activeExerciseId,
      ),
    );
  }

  Future<void> _onSetRecorded(
    LiveSessionSetRecorded event,
    Emitter<LiveSessionState> emit,
  ) async {
    final id = state.sessionId;
    if (id == null || state.completed) return;
    final tappedAt = _clock();
    var record = event.record;
    // Ejercicio cambiado solo hoy: la serie se guarda con el que se hizo.
    final swappedTo = state.originals.containsKey(record.plannedExerciseId)
        ? state.exercises
              .where((e) => e.id == record.plannedExerciseId)
              .firstOrNull
              ?.exerciseId
        : null;
    if (swappedTo != null && record.exerciseId == null) {
      record = record.copyWith(exerciseId: swappedTo);
    }
    // La serie que se cronometraba se guarda con su tiempo; sin cronómetro, sin
    // él (nunca obliga). Marcarla en pausa también reanuda la sesión. El
    // calentamiento no se cronometra.
    final timed =
        !record.warmup &&
        state.timerSet == record.setNumber &&
        state.timerExerciseId == record.plannedExerciseId;
    if (timed && record.activeSeconds == null) {
      final since = state.timerSince;
      final secs =
          state.timerBanked +
          (since == null
              ? 0
              : math.max(0, tappedAt.difference(since).inSeconds));
      record = record.copyWith(
        activeSeconds: math.min(secs, _maxExerciseSeconds).toInt(),
      );
      emit(_withoutTimer(state));
      await _persistDraft();
    }
    if (state.paused) await _resumeNow(emit);
    // Mientras se guarda o se sube otra, esta espera en la cola en vez de perderse.
    if (state.saving) {
      await _queue(emit, id, record, tappedAt, keepSaving: true);
      return;
    }
    emit(state.copyWith(saving: true));
    // Con series pendientes, esta va detrás de ellas para no desordenarlas.
    if (state.pendingSets.isNotEmpty) {
      await _queue(emit, id, record, tappedAt);
      return;
    }
    final result = await _recordSet(id, record);
    switch (result) {
      // Sin conexión: la serie se guarda en el teléfono y se sube después.
      case Failure(error: NetworkError()):
        await _queue(emit, id, record, tappedAt);
        return;
      case Success(value: final session):
        emit(
          _afterSet(
            state.copyWith(
              saving: false,
              session: _withPending(session, state.pendingSets),
            ),
            record,
            tappedAt,
            // Si mientras tanto se apuntó otra, su descanso es el que vale.
            startRest: state.pendingSets.isEmpty,
          ),
        );
        // Si otra serie esperó en la cola mientras esta se guardaba, se sube ya.
        if (state.pendingSets.isNotEmpty) {
          add(const LiveSessionEvent.pendingRetried());
        }
      case Failure(:final error):
        emit(state.copyWith(saving: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  /// Guarda [record] como pendiente (también en el teléfono) y lo muestra; el
  /// descanso arranca igual que si se hubiera subido. Con [keepSaving] no toca
  /// `saving`: otra operación en curso lo apagará.
  Future<void> _queue(
    Emitter<LiveSessionState> emit,
    String sessionId,
    SetRecord record,
    DateTime tappedAt, {
    bool keepSaving = false,
  }) async {
    // Se publica antes de guardar en el teléfono: dos series apuntadas a la
    // vez (sin conexión) leen la cola ya actualizada y ninguna pisa a la otra.
    final pending = [...state.pendingSets, record];
    final session = state.session;
    emit(
      _afterSet(
        state.copyWith(
          saving: keepSaving && state.saving,
          pendingSets: pending,
          session: session == null ? null : _withPending(session, [record]),
        ),
        record,
        tappedAt,
      ),
    );
    await _savePending(sessionId, state.pendingSets);
  }

  /// Añade a la sesión del servidor las series pendientes (con id local
  /// «pending-N», N su posición en la cola): las de calentamiento van a su
  /// lista. [sets] son las que faltan por añadir, detrás de las ya añadidas.
  TrainingSession _withPending(TrainingSession session, List<SetRecord> sets) {
    if (sets.isEmpty) return session;
    bool local(SessionSet s) => s.id.startsWith(pendingPrefix);
    final offset =
        session.sets.where(local).length +
        session.warmupSets.where(local).length;
    SessionSet toSet(int i, SetRecord r) => SessionSet(
      id: '$pendingPrefix${offset + i}',
      plannedExerciseId: r.plannedExerciseId,
      setNumber: r.setNumber,
      repsDone: r.repsDone,
      weightKg: r.weightKg,
      completed: r.completed,
      failedReps: r.failedReps,
      durationSeconds: r.durationSeconds,
      distanceMeters: r.distanceMeters,
      activeSeconds: r.activeSeconds,
      exerciseId: r.exerciseId,
      warmup: r.warmup,
      toFailure: r.toFailure,
    );
    return session.copyWith(
      sets: [
        ...session.sets,
        for (final (i, r) in sets.indexed)
          if (!r.warmup) toSet(i, r),
      ],
      warmupSets: [
        ...session.warmupSets,
        for (final (i, r) in sets.indexed)
          if (r.warmup) toSet(i, r),
      ],
    );
  }

  /// Sube las pendientes en orden; para en el primer fallo que pueda arreglarse
  /// reintentando (sin red, servidor caído o sesión caducada).
  Future<void> _flushPending(Emitter<LiveSessionState> emit) async {
    final id = state.sessionId;
    if (id == null || state.pendingSets.isEmpty || state.saving) return;
    emit(state.copyWith(saving: true));
    final taken = state.pendingSets.length;
    var pending = [...state.pendingSets];
    TrainingSession? latest;
    var discarded = false;
    while (pending.isNotEmpty) {
      final result = await _recordSet(id, pending.first);
      final session = result.valueOrNull;
      if (session == null) {
        if (_retryable(result.errorOrNull)) break;
        // El servidor la rechaza (datos no válidos, sesión cerrada…): reintentar
        // no lo arregla, así que se descarta y se avisa.
        discarded = true;
        pending = pending.sublist(1);
        continue;
      }
      latest = session;
      pending = pending.sublist(1);
    }
    // Las que se apuntaron mientras tanto van detrás.
    pending = [...pending, ...state.pendingSets.skip(taken)];
    await _savePending(id, pending);
    if (discarded) {
      _effect(
        emit,
        const TrainingEffect.message(TrainingMessage.pendingSetDiscarded),
      );
    }
    final base = latest ?? state.session;
    emit(
      state.copyWith(
        saving: false,
        pendingSets: pending,
        session: base == null ? null : _withPending(_serverOnly(base), pending),
      ),
    );
  }

  /// La sesión sin las series pendientes que se le añadieron para mostrarlas.
  TrainingSession _serverOnly(TrainingSession session) => session.copyWith(
    sets: [
      for (final s in session.sets)
        if (!s.id.startsWith(pendingPrefix)) s,
    ],
    warmupSets: [
      for (final s in session.warmupSets)
        if (!s.id.startsWith(pendingPrefix)) s,
    ],
  );

  static bool _retryable(AppError? error) => switch (error) {
    NetworkError() || ServerError() || UnauthorizedError() => true,
    UnknownAppError() || null => true,
    _ => false,
  };

  Future<void> _onSetDeleted(
    LiveSessionSetDeleted event,
    Emitter<LiveSessionState> emit,
  ) async {
    final id = state.sessionId;
    if (id == null || state.saving || state.completed) return;
    // Una serie que aún no subió se borra solo del teléfono.
    if (event.setId.startsWith(pendingPrefix)) {
      final session = state.session;
      if (session == null) return;
      // El número del id local es su posición en la cola de pendientes.
      final index =
          int.tryParse(event.setId.substring(pendingPrefix.length)) ?? -1;
      if (index < 0 || index >= state.pendingSets.length) return;
      final pending = [...state.pendingSets]..removeAt(index);
      await _savePending(id, pending);
      emit(
        state.copyWith(
          pendingSets: pending,
          session: _withPending(_serverOnly(session), pending),
        ),
      );
      return;
    }
    emit(state.copyWith(saving: true));
    final result = await _deleteSet(id, event.setId);
    switch (result) {
      case Success(value: final session):
        emit(state.copyWith(saving: false, session: session));
      case Failure(:final error):
        emit(state.copyWith(saving: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onFinish(
    LiveSessionFinishRequested event,
    Emitter<LiveSessionState> emit,
  ) async {
    final id = state.sessionId;
    if (id == null || state.finishing || state.completed) return;
    // Terminar lo calcula el servidor (experiencia, carga): antes deben subir
    // todas las series apuntadas sin conexión y la reanudación que no llegó
    // (si no, el servidor contaría como pausa lo entrenado después).
    await _retryResume(emit);
    await _flushPending(emit);
    if (state.pendingSets.isNotEmpty || state.resumePendingAt != null) {
      _effect(emit, const TrainingEffect.error(AppError.network()));
      return;
    }
    emit(
      state.copyWith(finishing: true, restRemaining: null, restEndsAt: null),
    );
    final realDurations = <String, int>{
      for (final entry in state.exerciseSeconds.entries)
        if (entry.value > 0)
          entry.key: math.min(entry.value, _maxExerciseSeconds),
    };
    final result = await _finish(
      id,
      durationSeconds: state.elapsedSeconds.clamp(1, _maxSessionSeconds),
      rpe: event.rpe.clamp(1, 10),
      realDurations: realDurations,
    );
    switch (result) {
      case Success(value: final finished):
        emit(state.copyWith(finishing: false, session: finished.session));
        await _saveDraft(id, const LiveSessionDraft());
        // La experiencia cambia el nivel: se refresca la cuenta global.
        final account = await _getAccount();
        if (account case Success(:final value)) {
          _effect(emit, TrainingEffect.accountChanged(value));
        }
        _effect(emit, TrainingEffect.sessionFinished(finished));
      case Failure(:final error):
        emit(state.copyWith(finishing: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onAbandon(
    LiveSessionAbandonRequested event,
    Emitter<LiveSessionState> emit,
  ) async {
    final id = state.sessionId;
    if (id == null || state.finishing) return;
    emit(state.copyWith(finishing: true));
    final result = await _cancel(id);
    emit(state.copyWith(finishing: false));
    switch (result) {
      case Success():
        await _saveDraft(id, const LiveSessionDraft());
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.sessionAbandoned),
        );
        _effect(emit, const TrainingEffect.close());
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  static LiveSessionState _withoutTimer(LiveSessionState s) => s.copyWith(
    timerExerciseId: null,
    timerSet: null,
    timerSince: null,
    timerBanked: 0,
    timerSeconds: 0,
  );

  void _onSetTimerStarted(
    LiveSessionSetTimerStarted event,
    Emitter<LiveSessionState> emit,
  ) {
    if (state.status != LiveStatus.ready || state.completed) return;
    emit(
      state.copyWith(
        timerExerciseId: event.plannedExerciseId,
        timerSet: event.setNumber,
        timerSince: _clock(),
        timerBanked: 0,
        timerSeconds: 0,
        restRemaining: null,
        restEndsAt: null,
      ),
    );
    if (state.paused) add(const LiveSessionEvent.resumeRequested());
    unawaited(_persistDraft());
  }

  /// Pausa al momento (también sin conexión: al terminar, el servidor nunca
  /// guarda más tiempo del que manda el cliente) y lo confirma con el servidor.
  Future<void> _onPause(
    LiveSessionPauseRequested event,
    Emitter<LiveSessionState> emit,
  ) async {
    final session = state.session;
    final id = state.sessionId;
    if (session == null || id == null || state.completed || session.isPaused) {
      return;
    }
    final now = _clock();
    final since = state.timerSince;
    emit(
      state.copyWith(
        session: session.copyWith(pausedAt: now),
        timerSince: null,
        timerBanked: since == null
            ? state.timerBanked
            : state.timerBanked + math.max(0, now.difference(since).inSeconds),
      ),
    );
    await _persistDraft();
    // Una reanudación que no llegó va antes: si no, esta pausa se juntaría con
    // la anterior en el servidor.
    await _retryResume(emit);
    final result = await _pauseSession(id);
    if (result case Success(value: final server)) {
      final current = state.session;
      if (current != null && current.isPaused) {
        emit(
          state.copyWith(
            session: current.copyWith(
              pausedAt: server.pausedAt ?? current.pausedAt,
              pausedSeconds: math.max(
                current.pausedSeconds,
                server.pausedSeconds,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _onResume(
    LiveSessionResumeRequested event,
    Emitter<LiveSessionState> emit,
  ) => _resumeNow(emit);

  /// Reanuda al momento y lo confirma con el servidor (también al marcar una
  /// serie en pausa, antes de guardarla, para que su respuesta ya venga
  /// reanudada).
  Future<void> _resumeNow(Emitter<LiveSessionState> emit) async {
    final session = state.session;
    final id = state.sessionId;
    final pausedAt = session?.pausedAt;
    if (session == null || id == null || state.completed || pausedAt == null) {
      return;
    }
    final now = _clock();
    emit(
      state.copyWith(
        session: session.copyWith(
          pausedAt: null,
          pausedSeconds:
              session.pausedSeconds +
              math.max(0, now.difference(pausedAt).inSeconds),
        ),
        countedUntil: now,
        timerSince: state.timerSet != null ? now : null,
      ),
    );
    await _persistDraft();
    // Si ya había una reanudación sin llegar, vale la primera: lo que va de
    // una a otra se entrenó (el servidor no supo de la pausa intermedia).
    await _sendResume(emit, id, state.resumePendingAt ?? now);
  }

  /// Avisa al servidor de que se reanudó en [at]. Sin conexión, lo deja
  /// pendiente para reintentarlo (con esa misma hora) antes de terminar.
  Future<void> _sendResume(
    Emitter<LiveSessionState> emit,
    String id,
    DateTime at,
  ) async {
    final result = await _resumeSession(id, resumedAt: at);
    switch (result) {
      case Success(value: final server):
        final current = state.session;
        emit(
          state.copyWith(
            resumePendingAt: null,
            // Sin conexión el servidor pudo no ver una pausa: manda la mayor.
            session: current == null || current.isPaused
                ? current
                : current.copyWith(
                    pausedSeconds: math.max(
                      current.pausedSeconds,
                      server.pausedSeconds,
                    ),
                  ),
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            resumePendingAt: _retryable(error) ? at : null,
          ),
        );
    }
  }

  /// Reintenta la reanudación que no llegó al servidor (si la hay).
  Future<void> _retryResume(Emitter<LiveSessionState> emit) async {
    final id = state.sessionId;
    final at = state.resumePendingAt;
    if (id == null || at == null || state.completed) return;
    await _sendResume(emit, id, at);
  }

  /// Recupera lo que guardó el teléfono: ejercicios cambiados hoy y el
  /// cronómetro de la serie (si esa serie no se marcó ya).
  void _restoreDraft(Emitter<LiveSessionState> emit, LiveSessionDraft draft) {
    if (draft.isEmpty) return;
    var next = state;
    for (final entry in draft.swaps.entries) {
      next = _swapped(next, entry.key, entry.value);
    }
    final set = draft.timerSet;
    final plannedId = draft.timerPlannedExerciseId;
    final alreadyLogged =
        set != null &&
        (next.session?.setsFor(plannedId).any((s) => s.setNumber == set) ??
            false);
    if (set != null && !alreadyLogged) {
      var since = draft.timerSince;
      var banked = draft.timerBanked;
      // Si la sesión quedó en pausa, lo que corrió hasta la pausa ya cuenta y
      // el cronómetro espera a «Reanudar».
      final pausedAt = next.session?.pausedAt;
      if (since != null && pausedAt != null) {
        banked += math.max(0, pausedAt.difference(since).inSeconds);
        since = null;
      }
      final now = _clock();
      next = next.copyWith(
        timerExerciseId: plannedId,
        timerSet: set,
        timerSince: since,
        timerBanked: banked,
        timerSeconds: since == null
            ? banked
            : banked + math.max(0, now.difference(since).inSeconds),
      );
    }
    emit(next);
  }

  /// Guarda en el teléfono el cronómetro y los cambios de hoy (si falla, solo
  /// se pierde eso al cerrar la app: no bloquea la sesión).
  Future<void> _persistDraft() async {
    final id = state.sessionId;
    if (id == null || state.completed) return;
    await _saveDraft(
      id,
      LiveSessionDraft(
        timerPlannedExerciseId: state.timerExerciseId,
        timerSet: state.timerSet,
        timerSince: state.timerSince,
        timerBanked: state.timerBanked,
        swaps: {
          for (final e in state.exercises)
            if (state.originals.containsKey(e.id))
              e.id: ExerciseSwap(
                exerciseId: e.exerciseId,
                name: e.exerciseName,
                gifUrl: e.gifUrl,
                previewUrl: e.previewUrl,
              ),
        },
      ),
    );
  }

  /// «Usar hoy»: cambia el ejercicio de un hueco solo en esta sesión (la
  /// rutina no cambia); sin [ExerciseSwap], vuelve al original.
  Future<void> _onExerciseSwapped(
    LiveSessionExerciseSwapped event,
    Emitter<LiveSessionState> emit,
  ) async {
    if (state.status != LiveStatus.ready || state.completed) return;
    final swap = event.swap;
    if (swap == null) {
      final original = state.originals[event.plannedExerciseId];
      if (original == null) return;
      emit(
        state.copyWith(
          exercises: [
            for (final e in state.exercises)
              e.id == original.id ? original : e,
          ],
          originals: {...state.originals}..remove(original.id),
        ),
      );
    } else {
      emit(_swapped(state, event.plannedExerciseId, swap));
    }
    await _persistDraft();
  }

  /// [s] con el hueco [plannedId] haciendo [swap] (sin su propuesta de carga,
  /// que era para el ejercicio de la rutina).
  static LiveSessionState _swapped(
    LiveSessionState s,
    String plannedId,
    ExerciseSwap swap,
  ) {
    final current = s.exercises.where((e) => e.id == plannedId).firstOrNull;
    if (current == null) return s;
    final original = s.originals[plannedId] ?? current;
    if (swap.exerciseId == original.exerciseId) {
      return s.copyWith(
        exercises: [
          for (final e in s.exercises) e.id == plannedId ? original : e,
        ],
        originals: {...s.originals}..remove(plannedId),
      );
    }
    return s.copyWith(
      exercises: [
        for (final e in s.exercises)
          e.id == plannedId
              ? original.copyWith(
                  exerciseId: swap.exerciseId,
                  exerciseName: swap.name,
                  gifUrl: swap.gifUrl,
                  previewUrl: swap.previewUrl,
                )
              : e,
      ],
      originals: {...s.originals, plannedId: original},
      loadSuggestions: {...s.loadSuggestions}..remove(plannedId),
      acceptedLoad: {...s.acceptedLoad}..remove(plannedId),
    );
  }

  void _effect(Emitter<LiveSessionState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
