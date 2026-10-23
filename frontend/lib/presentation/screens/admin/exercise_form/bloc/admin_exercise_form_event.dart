part of 'admin_exercise_form_bloc.dart';

@freezed
sealed class AdminExerciseFormEvent with _$AdminExerciseFormEvent {
  /// [exerciseId] nulo abre el formulario de alta.
  const factory AdminExerciseFormEvent.started({String? exerciseId}) =
      AdminExerciseFormStarted;

  const factory AdminExerciseFormEvent.draftChanged(AdminExerciseDraft draft) =
      AdminExerciseFormDraftChanged;

  const factory AdminExerciseFormEvent.submitted() = AdminExerciseFormSubmitted;
}
