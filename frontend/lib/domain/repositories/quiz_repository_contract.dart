import '../models/academic/mock_exam_options.dart';
import '../models/academic/question_creation.dart';
import '../models/academic/quiz.dart';
import '../models/academic/subject_questions.dart';
import '../models/result/app_result.dart';

/// Bancos de preguntas, práctica libre, flashcards y sesiones de test.
abstract interface class QuizRepositoryContract {
  Future<AppResult<QuestionBank>> getQuestionBank(String materialId);

  /// «Crear preguntas» (ADR 0058): las del documento revisadas y las nuevas.
  Future<AppResult<QuestionBank>> generateQuestionBank(
    String materialId,
    CreateQuestionsRequest request,
  );

  /// Preguntas que ya trae escritas el documento del material (no guarda nada).
  Future<AppResult<DocumentQuestionScan>> scanDocumentQuestions(
    String materialId,
  );

  Future<AppResult<AnswerResult>> answerQuestion(
    String questionId,
    String answer,
  );

  /// «No lo sé» fuera de una sesión (ADR 0063): trae la solución.
  Future<AppResult<AnswerResult>> dontKnowQuestion(String questionId);

  /// [dontKnow]: preguntas contestadas con «No lo sé».
  Future<AppResult<PracticeResult>> completePractice(
    String bankId,
    Map<String, String> answers, {
    Set<String> dontKnow = const {},
  });

  /// Todas las preguntas de la asignatura con cómo va cada una (ADR 0063).
  Future<AppResult<SubjectQuestions>> getSubjectQuestions(String subjectId);

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

  /// Con [dontKnow] la respuesta es «No lo sé» y [answer] se ignora.
  Future<AppResult<SessionAnswer>> answerInSession(
    String sessionId, {
    required String questionId,
    required String answer,
    int? nextIndex,
    bool dontKnow = false,
  });

  Future<AppResult<TestSession>> completeTestSession(String sessionId);
}
