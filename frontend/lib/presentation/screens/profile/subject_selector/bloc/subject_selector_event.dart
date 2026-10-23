part of 'subject_selector_bloc.dart';

@freezed
sealed class SubjectSelectorEvent with _$SubjectSelectorEvent {
  const factory SubjectSelectorEvent.started() = SubjectSelectorStarted;

  /// `null` = todos los cursos.
  const factory SubjectSelectorEvent.courseChanged(int? course) =
      SubjectSelectorCourseChanged;

  /// `null` = ambos semestres.
  const factory SubjectSelectorEvent.semesterChanged(int? semester) =
      SubjectSelectorSemesterChanged;

  const factory SubjectSelectorEvent.queryChanged(String query) =
      SubjectSelectorQueryChanged;

  const factory SubjectSelectorEvent.moreRequested() =
      SubjectSelectorMoreRequested;

  const factory SubjectSelectorEvent.toggled(String subjectId) =
      SubjectSelectorToggled;

  /// Crea las asignaturas seleccionadas.
  const factory SubjectSelectorEvent.submitted() = SubjectSelectorSubmitted;
}
