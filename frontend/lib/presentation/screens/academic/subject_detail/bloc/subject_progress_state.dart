part of 'subject_progress_bloc.dart';

@freezed
abstract class SubjectProgressState with _$SubjectProgressState {
  const factory SubjectProgressState({
    @Default('') String subjectId,
    @Default(true) bool loading,
    AppError? error,
    TeachingGuide? guide,
    Retention? retention,
    @Default(<SubjectTimelineItem>[]) List<SubjectTimelineItem> timeline,
    @Default(<StudyMaterial>[]) List<StudyMaterial> materials,

    @Default(false) bool savingGrade,
    AppError? actionError,
  }) = _SubjectProgressState;
}
