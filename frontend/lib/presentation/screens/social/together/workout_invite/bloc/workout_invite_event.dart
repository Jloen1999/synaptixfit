part of 'workout_invite_bloc.dart';

@freezed
sealed class WorkoutInviteEvent with _$WorkoutInviteEvent {
  const factory WorkoutInviteEvent.submitted({
    required String routineId,
    String? dayId,
    required List<String> friendIds,
  }) = WorkoutInviteSubmitted;
}
