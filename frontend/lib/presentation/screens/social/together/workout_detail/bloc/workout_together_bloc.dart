import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/decline_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/join_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/leave_workout_together_use_case.dart';
import '../../../../../../domain/use_cases/social/together/start_workout_together_use_case.dart';

part 'workout_together_bloc.freezed.dart';
part 'workout_together_event.dart';
part 'workout_together_state.dart';

/// Detalle de «Entrenamos juntos» (ADR 0044). Mientras la pantalla está
/// abierta vuelve a leer cada [pollInterval] (sin WebSocket); «Empezar» abre la
/// sesión normal de la persona.
class WorkoutTogetherBloc
    extends Bloc<WorkoutTogetherEvent, WorkoutTogetherState> {
  WorkoutTogetherBloc({
    required this._get,
    required this._join,
    required this._decline,
    required this._leave,
    required this._start,
    this.pollInterval = const Duration(seconds: 15),
  }) : super(const WorkoutTogetherState()) {
    on<WorkoutTogetherStarted>(_onStarted);
    on<WorkoutTogetherPolled>(_onPolled);
    on<WorkoutTogetherJoined>(_onJoined);
    on<WorkoutTogetherDeclined>(_onDeclined);
    on<WorkoutTogetherLeft>(_onLeft);
    on<WorkoutTogetherStartRequested>(_onStart);
  }

  final GetWorkoutTogetherUseCaseContract _get;
  final JoinWorkoutTogetherUseCaseContract _join;
  final DeclineWorkoutTogetherUseCaseContract _decline;
  final LeaveWorkoutTogetherUseCaseContract _leave;
  final StartWorkoutTogetherUseCaseContract _start;
  final Duration pollInterval;
  Timer? _timer;

  String get _id => state.id!;

  Future<void> _onStarted(
    WorkoutTogetherStarted event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    emit(
      state.copyWith(
        id: event.id,
        status: WorkoutTogetherStatus.loading,
        error: null,
      ),
    );
    final result = await _get(event.id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: WorkoutTogetherStatus.ready,
        workout: value,
      ),
      Failure(:final error) => state.copyWith(
        status: WorkoutTogetherStatus.failure,
        error: error,
      ),
    });
    _timer?.cancel();
    _timer = Timer.periodic(
      pollInterval,
      (_) => add(const WorkoutTogetherEvent.polled()),
    );
  }

  /// Lectura silenciosa: un fallo de red no cambia lo que se ve.
  Future<void> _onPolled(
    WorkoutTogetherPolled event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.id == null || state.busy) return;
    final result = await _get(_id);
    if (result case Success(:final value)) {
      emit(state.copyWith(status: WorkoutTogetherStatus.ready, workout: value));
    }
  }

  Future<void> _onJoined(
    WorkoutTogetherJoined event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _join(_id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(busy: false, workout: value),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _onDeclined(
    WorkoutTogetherDeclined event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _decline(_id);
    emit(switch (result) {
      Success() => state.copyWith(busy: false, closed: true),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _onLeft(
    WorkoutTogetherLeft event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _leave(_id);
    emit(switch (result) {
      Success() => state.copyWith(busy: false, left: true),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(left: false, actionError: null));
  }

  Future<void> _onStart(
    WorkoutTogetherStartRequested event,
    Emitter<WorkoutTogetherState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _start(_id);
    emit(switch (result) {
      Success(:final value) => state.copyWith(busy: false, openSession: value),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(openSession: null, actionError: null));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
