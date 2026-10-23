import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/question_type.dart';
import '../../enums/test_session_status.dart';

part 'quiz.freezed.dart';

/// Banco de preguntas de un material (con soluciones).
@freezed
abstract class QuestionBank with _$QuestionBank {
  const factory QuestionBank({
    required String id,
    required String materialId,
    required bool xpAwarded,
    required int attemptedQuestions,
    required int correctQuestions,
    @Default(<Question>[]) List<Question> questions,
  }) = _QuestionBank;
}

/// Pregunta del banco.
@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required QuestionType type,
    required String statement,
    @Default(<String>[]) List<String> options,
    required int order,
    required String correctAnswer,
    String? explanation,
  }) = _Question;
}

/// Corrección de una respuesta.
@freezed
abstract class AnswerResult with _$AnswerResult {
  const factory AnswerResult({
    required String questionId,
    required bool correct,
    String? correctAnswer,
    String? explanation,
  }) = _AnswerResult;
}

/// Resultado de la práctica libre.
@freezed
abstract class PracticeResult with _$PracticeResult {
  const factory PracticeResult({
    required int correct,
    required int total,
    required int xpAwarded,
  }) = _PracticeResult;
}

/// Resultado de una ronda de flashcards.
@freezed
abstract class FlashcardReviewResult with _$FlashcardReviewResult {
  const factory FlashcardReviewResult({
    required int quality,
    required int xpAwarded,
  }) = _FlashcardReviewResult;
}

/// Sesión de test persistente (simulacro).
@freezed
abstract class TestSession with _$TestSession {
  const factory TestSession({
    required String id,
    required String materialId,
    required TestSessionStatus status,
    required int currentIndex,
    required int score,
    required int totalQuestions,
    required int answeredCount,
    required DateTime startedAt,
    DateTime? completedAt,
    required bool xpAwarded,
    required int xpGranted,
    @Default(<SessionQuestion>[]) List<SessionQuestion> questions,
  }) = _TestSession;

  const TestSession._();

  bool get inProgress => status == TestSessionStatus.inProgress;
}

/// Pregunta dentro de una sesión: la solución solo llega si ya se respondió.
@freezed
abstract class SessionQuestion with _$SessionQuestion {
  const factory SessionQuestion({
    required String id,
    required QuestionType type,
    required String statement,
    @Default(<String>[]) List<String> options,
    required bool answered,
    String? answer,
    bool? correct,
    String? correctAnswer,
    String? explanation,
  }) = _SessionQuestion;
}

/// Resumen de una sesión para el historial.
@freezed
abstract class TestSessionSummary with _$TestSessionSummary {
  const factory TestSessionSummary({
    required String id,
    required String materialId,
    required TestSessionStatus status,
    required int score,
    required int totalQuestions,
    required int answeredCount,
    required DateTime startedAt,
    DateTime? completedAt,
  }) = _TestSessionSummary;
}

/// Respuesta en una sesión: corrección y sesión actualizada.
@freezed
abstract class SessionAnswer with _$SessionAnswer {
  const factory SessionAnswer({
    required AnswerResult result,
    required TestSession session,
  }) = _SessionAnswer;
}
