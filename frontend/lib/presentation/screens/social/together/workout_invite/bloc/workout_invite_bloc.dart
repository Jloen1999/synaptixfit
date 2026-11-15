import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/create_workout_together_use_case.dart';

part 'workout_invite_bloc.freezed.dart';
part 'workout_invite_event.dart';
part 'workout_invite_state.dart';

/// «Entrenar con amigos» desde una rutina (ADR 0044): invita de 1 a 4 amigos a
/// hacer hoy el siguiente día (o el elegido). Los amigos (y su tope, del
/// servidor) los elige `FriendPickerBloc`.
class WorkoutInviteBloc extends Bloc<WorkoutInviteEvent, WorkoutInviteState> {
  WorkoutInviteBloc({required this._create})
    : super(const WorkoutInviteState()) {
    on<WorkoutInviteSubmitted>(_onSubmitted);
  }

  final CreateWorkoutTogetherUseCaseContract _create;

  Future<void> _onSubmitted(
    WorkoutInviteSubmitted event,
    Emitter<WorkoutInviteState> emit,
  ) async {
    if (state.saving || event.friendIds.isEmpty) return;
    emit(state.copyWith(saving: true, error: null));
    final result = await _create(
      routineId: event.routineId,
      dayId: event.dayId,
      friendIds: event.friendIds,
    );
    emit(switch (result) {
      Success(:final value) => state.copyWith(saving: false, created: value),
      Failure(:final error) => state.copyWith(saving: false, error: error),
    });
    emit(state.copyWith(error: null));
  }
}
