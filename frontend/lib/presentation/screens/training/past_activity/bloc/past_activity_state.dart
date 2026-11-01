part of 'past_activity_bloc.dart';

@freezed
abstract class PastActivityState with _$PastActivityState {
  const factory PastActivityState({
    @Default(false) bool submitting,

    /// Guardada: XP ganada (0 si se pasó del tope diario). La página cierra.
    int? savedXp,
    Account? updatedAccount,
    AppError? error,

    /// Rutina en curso (para apuntar uno de sus días) y el día que toca.
    @Default(false) bool loadingRoutine,
    @Default(false) bool routineLoaded,

    /// No se pudo cargar la rutina en curso (se puede reintentar).
    AppError? routineError,
    Routine? routine,
    String? pendingDayId,
  }) = _PastActivityState;
}
