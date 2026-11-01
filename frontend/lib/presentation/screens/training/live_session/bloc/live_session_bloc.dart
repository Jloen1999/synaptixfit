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
import '../../../../../domain/use_cases/training/record_set_use_case.dart';
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
    on<LiveSessionPendingRetried>((_, emit) => _flushPending(emit));
    on<LiveSessionAbandonRequested>(_onAbandon);
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
  final DateTime Function() _clock;

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

    final elapsed = session.isCompleted
        ? session.durationMinutes * 60
        : math.max(0, _clock().difference(session.startedAt).inSeconds);
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
    if (session.isCompleted) return;
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
    final ids = {for (final e in exercises) e.id};
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
    final elapsed = startedAt == null
        ? state.elapsedSeconds + delta
        : math.max(0, now.difference(startedAt).inSeconds);
    final active = state.activeExerciseId;
    final seconds = active == null || delta == 0
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
    if (state.pendingSets.isNotEmpty && !state.saving && retryDue) {
      add(const LiveSessionEvent.pendingRetried());
    }
    emit(
      state.copyWith(
        elapsedSeconds: elapsed,
        countedUntil: counted,
        exerciseSeconds: seconds,
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
    // Mientras se guarda o se sube otra, esta espera en la cola en vez de perderse.
    if (state.saving) {
      await _queue(emit, id, event.record, tappedAt, keepSaving: true);
      return;
    }
    emit(state.copyWith(saving: true));
    // Con series pendientes, esta va detrás de ellas para no desordenarlas.
    if (state.pendingSets.isNotEmpty) {
      await _queue(emit, id, event.record, tappedAt);
      return;
    }
    final result = await _recordSet(id, event.record);
    switch (result) {
      // Sin conexión: la serie se guarda en el teléfono y se sube después.
      case Failure(error: NetworkError()):
        await _queue(emit, id, event.record, tappedAt);
        return;
      case Success(value: final session):
        emit(
          _afterSet(
            state.copyWith(
              saving: false,
              session: _withPending(session, state.pendingSets),
            ),
            event.record,
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
    final pending = [...state.pendingSets, record];
    await _savePending(sessionId, pending);
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
  }

  /// Añade a la sesión del servidor las series pendientes (con id local).
  TrainingSession _withPending(TrainingSession session, List<SetRecord> sets) {
    if (sets.isEmpty) return session;
    final offset = session.sets
        .where((s) => s.id.startsWith(pendingPrefix))
        .length;
    return session.copyWith(
      sets: [
        ...session.sets,
        for (final (i, r) in sets.indexed)
          SessionSet(
            id: '$pendingPrefix${offset + i}',
            plannedExerciseId: r.plannedExerciseId,
            setNumber: r.setNumber,
            repsDone: r.repsDone,
            weightKg: r.weightKg,
            completed: r.completed,
            failedReps: r.failedReps,
            durationSeconds: r.durationSeconds,
            distanceMeters: r.distanceMeters,
          ),
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
      final local = session.sets
          .where((s) => s.id.startsWith(pendingPrefix))
          .toList();
      final index = local.indexWhere((s) => s.id == event.setId);
      if (index < 0) return;
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
    // todas las series apuntadas sin conexión.
    await _flushPending(emit);
    if (state.pendingSets.isNotEmpty) {
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
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.sessionAbandoned),
        );
        _effect(emit, const TrainingEffect.close());
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _effect(Emitter<LiveSessionState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
