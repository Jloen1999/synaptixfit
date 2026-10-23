part of 'mock_exam_bloc.dart';

@freezed
sealed class MockExamEvent with _$MockExamEvent {
  /// [resume] reanuda la sesión en curso; si no hay, crea una nueva.
  const factory MockExamEvent.started({
    required String materialId,
    @Default(false) bool resume,
  }) = MockExamStarted;

  const factory MockExamEvent.answerChanged(String answer) =
      MockExamAnswerChanged;

  const factory MockExamEvent.questionSelected(int index) =
      MockExamQuestionSelected;

  const factory MockExamEvent.answerSubmitted() = MockExamAnswerSubmitted;

  const factory MockExamEvent.completed() = MockExamCompleted;

  const factory MockExamEvent.abandoned() = MockExamAbandoned;
}
