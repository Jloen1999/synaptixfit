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

    /// Solo al crear preguntas: cuántas se pidieron y cuántas se guardaron
    /// (menos si falló una tanda de la IA o ya las tenías).
    int? requestedQuestions,
    int? createdQuestions,
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

    /// Todas las correctas («Varias correctas»); en el resto, la única.
    @Default(<String>[]) List<String> correctAnswers,
  }) = _Question;
}

/// Corrección de una respuesta. [dontKnow]: se contestó «No lo sé» (ADR
/// 0063): cuenta como fallo, trae la solución y la pregunta vuelve antes.
@freezed
abstract class AnswerResult with _$AnswerResult {
  const factory AnswerResult({
    required String questionId,
    required bool correct,
    String? correctAnswer,
    String? explanation,
    @Default(<String>[]) List<String> correctAnswers,
    @Default(false) bool dontKnow,
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

    /// Falso si está abandonada (p. ej. se entregó sin ninguna respuesta): no
    /// cuenta (ni nota, ni XP, ni historial, ni repaso; ADR 0063).
    @Default(true) bool counted,

    /// Si entregarla ahora contaría (tiene alguna respuesta): lo decide el
    /// servidor y el diálogo de entregar lo explica.
    @Default(true) bool countsIfSubmitted,
  }) = _TestSession;

  const TestSession._();

  bool get inProgress => status == TestSessionStatus.inProgress;
}

/// Pregunta dentro de una sesión: la solución solo llega si ya se respondió.
/// [dontKnow]: contestada con «No lo sé»; [unanswered]: seguía sin contestar
/// al entregar y pasó a «No lo sé» (ADR 0063).
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
    @Default(<String>[]) List<String> correctAnswers,
    @Default(false) bool dontKnow,
    @Default(false) bool unanswered,
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
