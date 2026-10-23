part of 'subject_progress_bloc.dart';

@freezed
sealed class SubjectProgressEvent with _$SubjectProgressEvent {
  const factory SubjectProgressEvent.started(String subjectId) =
      SubjectProgressStarted;

  const factory SubjectProgressEvent.refreshed() = SubjectProgressRefreshed;

  /// Modalidad de evaluación con la que se calcula la nota.
  const factory SubjectProgressEvent.modeChanged(EvaluationMode mode) =
      SubjectProgressModeChanged;

  const factory SubjectProgressEvent.topicToggled({
    required int index,
    required bool completed,
  }) = SubjectProgressTopicToggled;

  /// [grade] nulo borra la nota del criterio.
  const factory SubjectProgressEvent.gradeChanged({
    required int index,
    double? grade,
  }) = SubjectProgressGradeChanged;
}
