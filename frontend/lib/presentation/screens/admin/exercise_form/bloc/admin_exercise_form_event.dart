part of 'admin_exercise_form_bloc.dart';

@freezed
sealed class AdminExerciseFormEvent with _$AdminExerciseFormEvent {
  /// [exerciseId] nulo abre el formulario de alta.
  const factory AdminExerciseFormEvent.started({String? exerciseId}) =
      AdminExerciseFormStarted;

  const factory AdminExerciseFormEvent.draftChanged(AdminExerciseDraft draft) =
      AdminExerciseFormDraftChanged;

  /// Pide a la IA el nombre en los demás idiomas. Con [onlyIfEmpty] (al
  /// terminar de escribir el nombre) no pisa lo que ya haya escrito.
  const factory AdminExerciseFormEvent.namesSuggested({
    @Default(false) bool onlyIfEmpty,
  }) = AdminExerciseFormNamesSuggested;

  const factory AdminExerciseFormEvent.submitted() = AdminExerciseFormSubmitted;
}
