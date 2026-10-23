part of 'subject_form_bloc.dart';

@freezed
sealed class SubjectFormEvent with _$SubjectFormEvent {
  /// [subjectId] nulo = alta nueva.
  const factory SubjectFormEvent.started({String? subjectId}) =
      SubjectFormStarted;

  /// [course] y [semester] nulos quitan el curso/semestre asignado.
  const factory SubjectFormEvent.submitted({
    required SubjectInput input,
    int? course,
    int? semester,
  }) = SubjectFormSubmitted;
}
