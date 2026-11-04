import '../../domain/models/academic/mock_exam_options.dart';
import '../../domain/models/academic/quiz.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/quiz_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/quiz_remote_data_source.dart';

class QuizRepository implements QuizRepositoryContract {
  QuizRepository(this._remote);

  final QuizRemoteDataSource _remote;

  @override
  Future<AppResult<QuestionBank>> getQuestionBank(String materialId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getBank(materialId)).toDomain(),
      );

  @override
  Future<AppResult<QuestionBank>> generateQuestionBank(String materialId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.generateBank(materialId)).toDomain(),
      );

  @override
  Future<AppResult<AnswerResult>> answerQuestion(
    String questionId,
    String answer,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.answer(questionId, answer)).toDomain(),
  );

  @override
  Future<AppResult<PracticeResult>> completePractice(
    String bankId,
    Map<String, String> answers,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.completePractice(bankId, answers)).toDomain(),
  );

  @override
  Future<AppResult<FlashcardReviewResult>> reviewFlashcards(
    String materialId, {
    required int mastered,
    required int doubtful,
    required int failed,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.reviewFlashcards(
      materialId,
      mastered,
      doubtful,
      failed,
    )).toDomain(),
  );

  @override
  Future<AppResult<MockExamOptions>> getMockExamOptions(String subjectId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getMockExamOptions(subjectId)).toDomain(),
      );

  @override
  Future<AppResult<TestSession>> startTestSession(
    List<String> materialIds, {
    int? questionCount,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.start(materialIds, questionCount)).toDomain(),
  );

  @override
  Future<AppResult<TestSession?>> getActiveTestSession(String materialId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getActive(materialId))?.toDomain(),
      );

  @override
  Future<AppResult<TestSession>> getTestSession(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getSession(sessionId)).toDomain(),
      );

  @override
  Future<AppResult<List<TestSessionSummary>>> getTestSessions(
    String materialId,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.getSessions(
      materialId,
    )).map((s) => s.toDomain()).toList(),
  );

  @override
  Future<AppResult<SessionAnswer>> answerInSession(
    String sessionId, {
    required String questionId,
    required String answer,
    int? nextIndex,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.answerInSession(
      sessionId,
      questionId,
      answer,
      nextIndex,
    )).toDomain(),
  );

  @override
  Future<AppResult<TestSession>> completeTestSession(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.complete(sessionId)).toDomain(),
      );

  @override
  Future<AppResult<TestSession>> abandonTestSession(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.abandon(sessionId)).toDomain(),
      );
}
