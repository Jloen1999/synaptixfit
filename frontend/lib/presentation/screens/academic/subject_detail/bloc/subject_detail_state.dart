part of 'subject_detail_bloc.dart';

@freezed
abstract class SubjectDetailState with _$SubjectDetailState {
  const factory SubjectDetailState({
    @Default('') String subjectId,
    @Default(true) bool loading,
    AppError? error,
    Subject? subject,
    SubjectSemester? semester,
    @Default(false) bool busy,
    AppError? actionError,
    @Default(false) bool deleted,
  }) = _SubjectDetailState;
}
