part of 'admin_exercises_bloc.dart';

/// Resultado puntual de una acción sobre un ejercicio.
@freezed
sealed class AdminExercisesEffect with _$AdminExercisesEffect {
  const factory AdminExercisesEffect.activeChanged({required bool active}) =
      AdminExercisesActiveChangedEffect;

  const factory AdminExercisesEffect.deleted() = AdminExercisesDeletedEffect;

  /// El ejercicio está en uso y el servidor lo ha desactivado en lugar de borrarlo.
  const factory AdminExercisesEffect.deactivatedInstead() =
      AdminExercisesDeactivatedInsteadEffect;

  const factory AdminExercisesEffect.failure(AppError error) =
      AdminExercisesFailureEffect;
}

@freezed
abstract class AdminExercisesState with _$AdminExercisesState {
  const factory AdminExercisesState({
    @Default(AdminStatus.initial) AdminStatus status,
    @Default(AdminExerciseQuery()) AdminExerciseQuery query,
    @Default(0) int page,
    AdminPage<AdminExercise>? exercises,
    String? busyId,
    AdminExercisesEffect? effect,
    AppError? error,
  }) = _AdminExercisesState;
}
