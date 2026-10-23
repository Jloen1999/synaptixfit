import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/use_cases/training/get_last_performance_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_bookends_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/training/cancel_session_use_case.dart';
import '../../../../../domain/use_cases/training/delete_set_use_case.dart';
import '../../../../../domain/use_cases/training/finish_session_use_case.dart';
import '../../../../../domain/use_cases/training/get_routine_use_case.dart';
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
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const LiveSessionState()) {
    on<LiveSessionStarted>(_onStarted);
    on<LiveSessionTicked>(_onTicked);
    on<LiveSessionExerciseSelected>(
      (e, emit) => emit(state.copyWith(activeExerciseId: e.plannedExerciseId)),
    );
    on<LiveSessionSetRecorded>(_onSetRecorded);
    on<LiveSessionSetDeleted>(_onSetDeleted);
    on<LiveSessionRestStarted>(
      (e, emit) =>
          emit(state.copyWith(restRemaining: e.seconds, restTotal: e.seconds)),
    );
    on<LiveSessionRestAdjusted>((e, emit) {
      final remaining = state.restRemaining;
      if (remaining == null) return;
      final next = math.max(0, remaining + e.deltaSeconds);
      emit(
        next == 0
            ? state.copyWith(restRemaining: null)
            : state.copyWith(
                restRemaining: next,
                restTotal: math.max(state.restTotal, next),
              ),
      );
    });
    on<LiveSessionRestSkipped>(
      (_, emit) => emit(state.copyWith(restRemaining: null)),
    );
    on<LiveSessionFinishRequested>(_onFinish);
    on<LiveSessionAbandonRequested>(_onAbandon);
  }

  final GetSessionUseCaseContract _getSession;
  final GetRoutineUseCaseContract _getRoutine;
  final RecordSetUseCaseContract _recordSet;
  final DeleteSetUseCaseContract _deleteSet;
  final FinishSessionUseCaseContract _finish;
  final CancelSessionUseCaseContract _cancel;
  final GetAccountUseCaseContract _getAccount;
  final GetLastPerformanceUseCaseContract _getLastPerformance;
  final GetSessionBookendsUseCaseContract _getBookends;
  final DateTime Function() _clock;

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

    final elapsed = session.isCompleted
        ? session.durationMinutes * 60
        : math.max(0, _clock().difference(session.startedAt).inSeconds);
    emit(
      state.copyWith(
        status: LiveStatus.ready,
        session: session,
        exercises: exercises,
        routineName: routineName,
        dayNumber: day?.dayNumber,
        dayName: day?.name,
        elapsedSeconds: elapsed,
        activeExerciseId: _firstUnfinished(session, exercises),
      ),
    );
    if (session.isCompleted) return;
    // Ayudas que no bloquean la sesión: si fallan, simplemente no se muestran.
    final (last, bookends) = await (
      _getLastPerformance(),
      exercises.isEmpty
          ? Future.value(
              const Success<SessionBookends, AppError>(SessionBookends()),
            )
          : _getBookends([for (final e in exercises) e.exerciseId]),
    ).wait;
    final lastByExercise = {
      for (final r in last.valueOrNull ?? const <PersonalRecord>[])
        r.exerciseId: r,
    };
    final suggested = bookends.valueOrNull;
    final hasBookends =
        suggested != null &&
        (suggested.warmUp.isNotEmpty || suggested.coolDown.isNotEmpty);
    if (lastByExercise.isEmpty && !hasBookends) return;
    emit(
      state.copyWith(
        lastPerformance: lastByExercise,
        bookends: hasBookends ? suggested : null,
      ),
    );
  }

  /// Primer ejercicio con series pendientes (o el primero).
  String? _firstUnfinished(
    TrainingSession session,
    List<PlannedExercise> exercises,
  ) {
    for (final e in exercises) {
      final done = session.setsFor(e.id).where((s) => s.completed).length;
      if (done < e.parameters.sets) return e.id;
    }
    return exercises.isEmpty ? null : exercises.first.id;
  }

  void _onTicked(LiveSessionTicked event, Emitter<LiveSessionState> emit) {
    if (state.status != LiveStatus.ready || state.completed) return;
    final active = state.activeExerciseId;
    final seconds = active == null
        ? state.exerciseSeconds
        : {
            ...state.exerciseSeconds,
            active: (state.exerciseSeconds[active] ?? 0) + 1,
          };
    final rest = state.restRemaining;
    emit(
      state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
        exerciseSeconds: seconds,
        restRemaining: rest == null || rest <= 1 ? null : rest - 1,
      ),
    );
  }

  Future<void> _onSetRecorded(
    LiveSessionSetRecorded event,
    Emitter<LiveSessionState> emit,
  ) async {
    final id = state.sessionId;
    if (id == null || state.saving || state.completed) return;
    emit(state.copyWith(saving: true));
    final result = await _recordSet(id, event.record);
    switch (result) {
      case Success(value: final session):
        final planned = state.exercises
            .where((e) => e.id == event.record.plannedExerciseId)
            .firstOrNull;
        final rest = event.record.completed
            ? planned?.parameters.restSeconds
            : null;
        emit(
          state.copyWith(
            saving: false,
            session: session,
            restRemaining: rest ?? state.restRemaining,
            restTotal: rest ?? state.restTotal,
            activeExerciseId:
                event.record.plannedExerciseId ?? state.activeExerciseId,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(saving: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onSetDeleted(
    LiveSessionSetDeleted event,
    Emitter<LiveSessionState> emit,
  ) async {
    final id = state.sessionId;
    if (id == null || state.saving || state.completed) return;
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
    emit(state.copyWith(finishing: true, restRemaining: null));
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
