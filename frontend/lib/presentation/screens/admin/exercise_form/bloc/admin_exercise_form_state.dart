part of 'admin_exercise_form_bloc.dart';

/// Resultado del envío del formulario.
@freezed
sealed class AdminExerciseFormEffect with _$AdminExerciseFormEffect {
  const factory AdminExerciseFormEffect.saved(AdminExercise exercise) =
      AdminExerciseFormSavedEffect;

  const factory AdminExerciseFormEffect.failure(AppError error) =
      AdminExerciseFormFailureEffect;
}

@freezed
abstract class AdminExerciseFormState with _$AdminExerciseFormState {
  const factory AdminExerciseFormState({
    @Default(AdminStatus.initial) AdminStatus status,

    /// Nulo en el alta.
    String? exerciseId,
    @Default(AdminExerciseOptions()) AdminExerciseOptions options,
    @Default(AdminExerciseDraft()) AdminExerciseDraft draft,

    /// Estado activo del ejercicio editado (solo informativo).
    @Default(true) bool active,
    @Default(false) bool submitting,

    /// Se activa al intentar guardar para mostrar los errores de validación.
    @Default(false) bool showErrors,
    AdminExerciseFormEffect? effect,
    AppError? error,
  }) = _AdminExerciseFormState;

  const AdminExerciseFormState._();

  bool get isEditing => exerciseId != null;
}
