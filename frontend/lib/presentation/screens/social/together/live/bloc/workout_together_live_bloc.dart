import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/find_workout_together_by_session_use_case.dart';

part 'workout_together_live_bloc.freezed.dart';
part 'workout_together_live_event.dart';
part 'workout_together_live_state.dart';

/// Quién lleva qué en «Entrenamos juntos» dentro de la sesión en vivo y su
/// resumen (ADR 0044). Si la sesión no es de entrenar juntos no pinta nada y no
/// vuelve a preguntar. Si lo es y es de hoy, consulta cada [pollInterval]
/// mientras la pantalla está abierta (sin WebSocket); un fallo de red no
/// cambia lo que se ve ni toca la sesión ni sus borradores.
class WorkoutTogetherLiveBloc
    extends Bloc<WorkoutTogetherLiveEvent, WorkoutTogetherLiveState> {
  WorkoutTogetherLiveBloc({
    required this._find,
    this.pollInterval = const Duration(seconds: 12),
  }) : super(const WorkoutTogetherLiveState()) {
    on<WorkoutTogetherLiveStarted>(_onStarted);
    on<WorkoutTogetherLivePolled>(_onPolled);
  }

  final FindWorkoutTogetherBySessionUseCaseContract _find;
  final Duration pollInterval;
  Timer? _timer;

  Future<void> _onStarted(
    WorkoutTogetherLiveStarted event,
    Emitter<WorkoutTogetherLiveState> emit,
  ) async {
    emit(state.copyWith(sessionId: event.sessionId));
    await _read(emit);
    final workout = state.workout;
    if (event.poll && workout != null && workout.today) {
      _timer?.cancel();
      _timer = Timer.periodic(
        pollInterval,
        (_) => add(const WorkoutTogetherLiveEvent.polled()),
      );
    }
  }

  Future<void> _onPolled(
    WorkoutTogetherLivePolled event,
    Emitter<WorkoutTogetherLiveState> emit,
  ) => _read(emit);

  Future<void> _read(Emitter<WorkoutTogetherLiveState> emit) async {
    final id = state.sessionId;
    if (id == null) return;
    final result = await _find(id);
    if (result case Success(:final value)) {
      emit(state.copyWith(loaded: true, workout: value));
      if (value == null) _timer?.cancel();
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
