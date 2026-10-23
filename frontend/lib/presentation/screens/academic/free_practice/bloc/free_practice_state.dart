part of 'free_practice_bloc.dart';

@freezed
abstract class FreePracticeState with _$FreePracticeState {
  const factory FreePracticeState({
    @Default(true) bool loading,
    AppError? error,
    QuestionBank? bank,
    @Default(0) int index,

    /// Respuesta que se está escribiendo o eligiendo.
    @Default('') String draft,

    /// Respuestas enviadas y su corrección, por id de pregunta.
    @Default(<String, String>{}) Map<String, String> answers,
    @Default(<String, AnswerResult>{}) Map<String, AnswerResult> results,
    @Default(false) bool checking,
    @Default(false) bool finishing,
    AppError? actionError,
    PracticeResult? result,
    Account? updatedAccount,
  }) = _FreePracticeState;

  const FreePracticeState._();

  Question? get current {
    final questions = bank?.questions ?? const <Question>[];
    return index < questions.length ? questions[index] : null;
  }

  int get total => bank?.questions.length ?? 0;

  bool get isLast => index >= total - 1;

  /// Corrección de la pregunta actual, si ya se respondió.
  AnswerResult? get currentResult =>
      current == null ? null : results[current!.id];
}
