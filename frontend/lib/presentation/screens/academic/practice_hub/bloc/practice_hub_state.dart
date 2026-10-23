part of 'practice_hub_bloc.dart';

@freezed
abstract class PracticeHubState with _$PracticeHubState {
  const factory PracticeHubState({
    @Default('') String materialId,
    @Default(true) bool loading,
    AppError? error,
    StudyMaterial? material,

    /// `null` si el material aún no tiene preguntas.
    QuestionBank? bank,
    TestSession? activeSession,
    @Default(<TestSessionSummary>[]) List<TestSessionSummary> sessions,
    @Default(false) bool generating,
    AppError? actionError,
  }) = _PracticeHubState;
}
