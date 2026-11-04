import '../models/academic/mock_exam_options.dart';
import '../models/academic/quiz.dart';
import '../models/result/app_result.dart';

/// Bancos de preguntas, práctica libre, flashcards y sesiones de test.
abstract interface class QuizRepositoryContract {
  Future<AppResult<QuestionBank>> getQuestionBank(String materialId);

  Future<AppResult<QuestionBank>> generateQuestionBank(String materialId);

  Future<AppResult<AnswerResult>> answerQuestion(
    String questionId,
    String answer,
  );

  Future<AppResult<PracticeResult>> completePractice(
    String bankId,
    Map<String, String> answers,
  );

  Future<AppResult<FlashcardReviewResult>> reviewFlashcards(
    String materialId, {
    required int mastered,
    required int doubtful,
    required int failed,
  });

  /// Materiales de la asignatura con preguntas para un simulacro.
  Future<AppResult<MockExamOptions>> getMockExamOptions(String subjectId);

  Future<AppResult<TestSession>> startTestSession(
    List<String> materialIds, {
    int? questionCount,
  });

  /// Sesión en curso del material o `null` si no hay ninguna.
  Future<AppResult<TestSession?>> getActiveTestSession(String materialId);

  Future<AppResult<TestSession>> getTestSession(String sessionId);

  Future<AppResult<List<TestSessionSummary>>> getTestSessions(
    String materialId,
  );

  Future<AppResult<SessionAnswer>> answerInSession(
    String sessionId, {
    required String questionId,
    required String answer,
    int? nextIndex,
  });

  Future<AppResult<TestSession>> completeTestSession(String sessionId);

  Future<AppResult<TestSession>> abandonTestSession(String sessionId);
}
