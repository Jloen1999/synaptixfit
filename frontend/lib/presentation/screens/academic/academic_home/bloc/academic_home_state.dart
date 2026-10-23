part of 'academic_home_bloc.dart';

@freezed
abstract class AcademicHomeState with _$AcademicHomeState {
  const factory AcademicHomeState({
    @Default(true) bool loading,
    AppError? error,
    @Default(<Subject>[]) List<Subject> subjects,
    @Default(<StudyMaterial>[]) List<StudyMaterial> due,
    @Default(false) bool showArchived,
  }) = _AcademicHomeState;
}
