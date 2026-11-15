part of 'workout_together_bloc.dart';

enum WorkoutTogetherStatus { loading, ready, failure }

@freezed
abstract class WorkoutTogetherState with _$WorkoutTogetherState {
  const factory WorkoutTogetherState({
    String? id,
    @Default(WorkoutTogetherStatus.loading) WorkoutTogetherStatus status,
    WorkoutTogether? workout,
    AppError? error,
    @Default(false) bool busy,

    /// Sesión que hay que abrir (efecto de un solo uso).
    String? openSession,

    /// La sesión se abre sola porque empezó otra persona (se anuncia al
    /// lector; efecto de un solo uso junto a [openSession]).
    @Default(false) bool startedByOther,

    /// Ha dicho que no a la invitación: la pantalla se cierra.
    @Default(false) bool closed,

    /// Acaba de salir (efecto de un solo uso: aviso con «Deshacer»).
    @Default(false) bool left,
    AppError? actionError,
  }) = _WorkoutTogetherState;
}
