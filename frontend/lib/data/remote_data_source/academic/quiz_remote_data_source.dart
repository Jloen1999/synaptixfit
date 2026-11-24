import 'package:dio/dio.dart';

import '../../../domain/enums/question_type.dart';
import '../api/api_client.dart';
import 'dto/question_creation_dtos.dart';
import 'dto/quiz_dtos.dart';

/// Endpoints de bancos de preguntas, «Crear preguntas», práctica, tarjetas y
/// sesiones de test. Cada llamada declara en `X-Question-Types` los tipos de
/// pregunta que sabe pintar esta app (ADR 0058): sin la cabecera, el servidor
/// no manda «Varias correctas» (apps anteriores).
class QuizRemoteDataSource {
  QuizRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _sessions = '/api/v1/test-sessions';

  /// Crear o leer preguntas va por tandas en el servidor (hasta 4, cada una
  /// con un reintento y 2 min de tope): se espera el peor caso para no dar
  /// por fallado algo que el servidor acaba guardando (ADR 0058).
  static const _aiTimeout = Duration(minutes: 16);

  static final Options _types = Options(
    headers: {
      'X-Question-Types': [
        for (final t in QuestionType.values) t.apiValue,
      ].join(','),
    },
  );

  /// `answers` (lista) si se eligieron varias; si no, `answer`.
  static Map<String, dynamic> _answerBody(String answer) {
    final parts = QuestionAnswers.split(answer);
    return parts.length > 1 ? {'answers': parts} : {'answer': answer};
  }

  Future<QuestionBankDto> getBank(String materialId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/study-materials/$materialId/question-bank',
      options: _types,
    );
    return QuestionBankDto.fromJson(response.data!);
  }

  Future<QuestionBankDto> generateBank(
    String materialId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/study-materials/$materialId/question-bank',
      data: body,
      options: _types.copyWith(receiveTimeout: _aiTimeout),
    );
    return QuestionBankDto.fromJson(response.data!);
  }

  Future<DocumentQuestionScanDto> scanDocumentQuestions(
    String materialId,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/study-materials/$materialId/document-questions',
      options: _types.copyWith(receiveTimeout: _aiTimeout),
    );
    return DocumentQuestionScanDto.fromJson(response.data!);
  }

  Future<AnswerResultDto> answer(String questionId, String answer) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/questions/$questionId/attempts',
      data: _answerBody(answer),
      options: _types,
    );
    return AnswerResultDto.fromJson(response.data!);
  }

  /// «No lo sé» (ADR 0063): sin respuesta, el servidor devuelve la solución.
  Future<AnswerResultDto> dontKnow(String questionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/questions/$questionId/attempts',
      data: {'dontKnow': true},
      options: _types,
    );
    return AnswerResultDto.fromJson(response.data!);
  }

  Future<SubjectQuestionsDto> getSubjectQuestions(String subjectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/subjects/$subjectId/questions',
      options: _types,
    );
    return SubjectQuestionsDto.fromJson(response.data!);
  }

  Future<PracticeResultDto> completePractice(
    String bankId,
    Map<String, String> answers,
    Set<String> dontKnow,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/question-banks/$bankId/practice-completions',
      data: {
        'answers': {
          for (final e in answers.entries)
            if (QuestionAnswers.split(e.value).length <= 1) e.key: e.value,
        },
        'selections': {
          for (final e in answers.entries)
            if (QuestionAnswers.split(e.value).length > 1)
              e.key: QuestionAnswers.split(e.value),
        },
        if (dontKnow.isNotEmpty) 'dontKnow': dontKnow.toList(),
      },
      options: _types,
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
      options: _types,
    );
    return TestSessionDto.fromJson(response.data!);
  }

  /// La API responde 204 sin cuerpo cuando no hay sesión en curso.
  Future<TestSessionDto?> getActive(String materialId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_sessions/active',
      queryParameters: {'materialId': materialId},
      options: _types,
    );
    final data = response.data;
    return response.statusCode == 204 || data == null
        ? null
        : TestSessionDto.fromJson(data);
  }

  Future<TestSessionDto> getSession(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_sessions/$sessionId',
      options: _types,
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
    int? nextIndex, {
    bool dontKnow = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_sessions/$sessionId/answers',
      data: {
        'questionId': questionId,
        if (dontKnow) 'dontKnow': true else ..._answerBody(answer),
        'nextIndex': ?nextIndex,
      },
      options: _types,
    );
    return SessionAnswerDto.fromJson(response.data!);
  }

  Future<TestSessionDto> complete(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_sessions/$sessionId/complete',
      options: _types,
    );
    return TestSessionDto.fromJson(response.data!);
  }
}
