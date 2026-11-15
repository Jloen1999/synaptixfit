part of 'workout_invite_bloc.dart';

@freezed
abstract class WorkoutInviteState with _$WorkoutInviteState {
  const factory WorkoutInviteState({
    @Default(false) bool saving,

    /// Entreno creado (efecto de un solo uso: abrirlo).
    WorkoutTogether? created,
    AppError? error,
  }) = _WorkoutInviteState;
}
