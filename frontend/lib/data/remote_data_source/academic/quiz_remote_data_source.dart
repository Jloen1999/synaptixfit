import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/quiz_dtos.dart';

/// Endpoints de bancos de preguntas, práctica, flashcards y sesiones de test.
class QuizRemoteDataSource {
  QuizRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _sessions = '/api/v1/test-sessions';

  Future<QuestionBankDto> getBank(String materialId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/study-materials/$materialId/question-bank',
    );
    return QuestionBankDto.fromJson(response.data!);
  }

  Future<QuestionBankDto> generateBank(String materialId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/study-materials/$materialId/question-bank',
    );
    return QuestionBankDto.fromJson(response.data!);
  }

  Future<AnswerResultDto> answer(String questionId, String answer) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/questions/$questionId/attempts',
      data: {'answer': answer},
    );
    return AnswerResultDto.fromJson(response.data!);
  }

  Future<PracticeResultDto> completePractice(
    String bankId,
    Map<String, String> answers,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/question-banks/$bankId/practice-completions',
      data: {'answers': answers},
    );
    return PracticeResultDto.fromJson(response.data!);
  }

  Future<FlashcardReviewResponseDto> reviewFlashcards(
    String materialId,
    int mastered,
    int doubtful,
    int failed,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/study-materials/$materialId/flashcard-reviews',
      data: {'mastered': mastered, 'doubtful': doubtful, 'failed': failed},
    );
    return FlashcardReviewResponseDto.fromJson(response.data!);
  }

  Future<MockExamOptionsDto> getMockExamOptions(String subjectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/subjects/$subjectId/mock-exam-options',
    );
    return MockExamOptionsDto.fromJson(response.data!);
  }

  Future<TestSessionDto> start(
    List<String> materialIds,
    int? questionCount,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _sessions,
      data: {'materialIds': materialIds, 'questionCount': ?questionCount},
    );
    return TestSessionDto.fromJson(response.data!);
  }

  /// La API responde 204 sin cuerpo cuando no hay sesión en curso.
  Future<TestSessionDto?> getActive(String materialId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_sessions/active',
      queryParameters: {'materialId': materialId},
    );
    final data = response.data;
    return response.statusCode == 204 || data == null
        ? null
        : TestSessionDto.fromJson(data);
  }

  Future<TestSessionDto> getSession(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_sessions/$sessionId',
    );
    return TestSessionDto.fromJson(response.data!);
  }

  Future<List<TestSessionSummaryDto>> getSessions(String materialId) async {
    final response = await _dio.get<List<dynamic>>(
      _sessions,
      queryParameters: {'materialId': materialId},
    );
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TestSessionSummaryDto.fromJson)
        .toList();
  }

  Future<SessionAnswerDto> answerInSession(
    String sessionId,
    String questionId,
    String answer,
    int? nextIndex,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_sessions/$sessionId/answers',
      data: {
        'questionId': questionId,
        'answer': answer,
        'nextIndex': ?nextIndex,
      },
    );
    return SessionAnswerDto.fromJson(response.data!);
  }

  Future<TestSessionDto> complete(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_sessions/$sessionId/complete',
    );
    return TestSessionDto.fromJson(response.data!);
  }

  Future<TestSessionDto> abandon(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_sessions/$sessionId/abandon',
    );
    return TestSessionDto.fromJson(response.data!);
  }
}
