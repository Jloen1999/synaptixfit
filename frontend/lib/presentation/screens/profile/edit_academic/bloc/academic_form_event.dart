part of 'academic_form_bloc.dart';

@freezed
sealed class AcademicFormEvent with _$AcademicFormEvent {
  /// Con [loadExisting] a `false` (onboarding) no se consulta el perfil actual.
  const factory AcademicFormEvent.started({@Default(true) bool loadExisting}) =
      AcademicFormStarted;

  const factory AcademicFormEvent.degreeSelected(Degree degree) =
      AcademicFormDegreeSelected;

  const factory AcademicFormEvent.degreeCleared() = AcademicFormDegreeCleared;

  const factory AcademicFormEvent.submitted(AcademicProfileDraft draft) =
      AcademicFormSubmitted;
}
