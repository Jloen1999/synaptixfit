part of 'past_activity_bloc.dart';

@freezed
abstract class PastActivityState with _$PastActivityState {
  const factory PastActivityState({
    @Default(false) bool submitting,

    /// Guardada: XP ganada (0 si se pasó del tope diario). La página cierra.
    int? savedXp,
    Account? updatedAccount,
    AppError? error,
  }) = _PastActivityState;
}
