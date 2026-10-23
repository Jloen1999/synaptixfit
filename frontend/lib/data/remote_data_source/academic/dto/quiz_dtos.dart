import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/question_type.dart';
import '../../../../domain/enums/test_session_status.dart';
import '../../../../domain/models/academic/quiz.dart';

part 'quiz_dtos.freezed.dart';
part 'quiz_dtos.g.dart';

@freezed
abstract class QuestionDto with _$QuestionDto {
  const factory QuestionDto({
    required String id,
    String? type,
    @Default('') String statement,
    @Default(<String>[]) List<String> options,
    @Default(0) int order,
    @Default('') String correctAnswer,
    String? explanation,
  }) = _QuestionDto;

  const QuestionDto._();

  factory QuestionDto.fromJson(Map<String, dynamic> json) =>
      _$QuestionDtoFromJson(json);

  Question toDomain() => Question(
    id: id,
    type: QuestionType.fromApi(type),
    statement: statement,
    options: options,
    order: order,
    correctAnswer: correctAnswer,
    explanation: explanation,
  );
}

@freezed
abstract class QuestionBankDto with _$QuestionBankDto {
  const factory QuestionBankDto({
    required String id,
    required String materialId,
    @Default(false) bool xpAwarded,
    @Default(0) int attemptedQuestions,
    @Default(0) int correctQuestions,
    @Default(<QuestionDto>[]) List<QuestionDto> questions,
  }) = _QuestionBankDto;

  const QuestionBankDto._();

  factory QuestionBankDto.fromJson(Map<String, dynamic> json) =>
      _$QuestionBankDtoFromJson(json);

  /// Preguntas en el orden del banco.
  QuestionBank toDomain() => QuestionBank(
    id: id,
    materialId: materialId,
    xpAwarded: xpAwarded,
    attemptedQuestions: attemptedQuestions,
    correctQuestions: correctQuestions,
    questions: (questions.map((q) => q.toDomain()).toList()
      ..sort((a, b) => a.order.compareTo(b.order))),
  );
}

@freezed
abstract class AnswerResultDto with _$AnswerResultDto {
  const factory AnswerResultDto({
    required String questionId,
    @Default(false) bool correct,
    String? correctAnswer,
    String? explanation,
  }) = _AnswerResultDto;

  const AnswerResultDto._();

  factory AnswerResultDto.fromJson(Map<String, dynamic> json) =>
      _$AnswerResultDtoFromJson(json);

  AnswerResult toDomain() => AnswerResult(
    questionId: questionId,
    correct: correct,
    correctAnswer: correctAnswer,
    explanation: explanation,
  );
}

@freezed
abstract class PracticeResultDto with _$PracticeResultDto {
  const factory PracticeResultDto({
    @Default(0) int correct,
    @Default(0) int total,
    @Default(0) int xpAwarded,
  }) = _PracticeResultDto;

  const PracticeResultDto._();

  factory PracticeResultDto.fromJson(Map<String, dynamic> json) =>
      _$PracticeResultDtoFromJson(json);

  PracticeResult toDomain() =>
      PracticeResult(correct: correct, total: total, xpAwarded: xpAwarded);
}

@freezed
abstract class FlashcardReviewResponseDto with _$FlashcardReviewResponseDto {
  const factory FlashcardReviewResponseDto({
    @Default(0) int quality,
    @Default(0) int xpAwarded,
  }) = _FlashcardReviewResponseDto;

  const FlashcardReviewResponseDto._();

  factory FlashcardReviewResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FlashcardReviewResponseDtoFromJson(json);

  FlashcardReviewResult toDomain() =>
      FlashcardReviewResult(quality: quality, xpAwarded: xpAwarded);
}

@freezed
abstract class SessionQuestionDto with _$SessionQuestionDto {
  const factory SessionQuestionDto({
    required String id,
    String? type,
    @Default('') String statement,
    @Default(<String>[]) List<String> options,
    @Default(false) bool answered,
    String? answer,
    bool? correct,
    String? correctAnswer,
    String? explanation,
  }) = _SessionQuestionDto;

  const SessionQuestionDto._();

  factory SessionQuestionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionQuestionDtoFromJson(json);

  SessionQuestion toDomain() => SessionQuestion(
    id: id,
    type: QuestionType.fromApi(type),
    statement: statement,
    options: options,
    answered: answered,
    answer: answer,
    correct: correct,
    correctAnswer: correctAnswer,
    explanation: explanation,
  );
}

@freezed
abstract class TestSessionDto with _$TestSessionDto {
  const factory TestSessionDto({
    required String id,
    required String materialId,
    String? status,
    @Default(0) int currentIndex,
    @Default(0) int score,
    @Default(0) int totalQuestions,
    @Default(0) int answeredCount,
    required DateTime startedAt,
    DateTime? completedAt,
    @Default(false) bool xpAwarded,
    @Default(0) int xpGranted,
    @Default(<SessionQuestionDto>[]) List<SessionQuestionDto> questions,
  }) = _TestSessionDto;

  const TestSessionDto._();

  factory TestSessionDto.fromJson(Map<String, dynamic> json) =>
      _$TestSessionDtoFromJson(json);

  TestSession toDomain() => TestSession(
    id: id,
    materialId: materialId,
    status: TestSessionStatus.fromApi(status),
    currentIndex: currentIndex,
    score: score,
    totalQuestions: totalQuestions,
    answeredCount: answeredCount,
    startedAt: startedAt.toLocal(),
    completedAt: completedAt?.toLocal(),
    xpAwarded: xpAwarded,
    xpGranted: xpGranted,
    questions: questions.map((q) => q.toDomain()).toList(),
  );
}

@freezed
abstract class TestSessionSummaryDto with _$TestSessionSummaryDto {
  const factory TestSessionSummaryDto({
    required String id,
    required String materialId,
    String? status,
    @Default(0) int score,
    @Default(0) int totalQuestions,
    @Default(0) int answeredCount,
    required DateTime startedAt,
    DateTime? completedAt,
  }) = _TestSessionSummaryDto;

  const TestSessionSummaryDto._();

  factory TestSessionSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TestSessionSummaryDtoFromJson(json);

  TestSessionSummary toDomain() => TestSessionSummary(
    id: id,
    materialId: materialId,
    status: TestSessionStatus.fromApi(status),
    score: score,
    totalQuestions: totalQuestions,
    answeredCount: answeredCount,
    startedAt: startedAt.toLocal(),
    completedAt: completedAt?.toLocal(),
  );
}

@freezed
abstract class SessionAnswerDto with _$SessionAnswerDto {
  const factory SessionAnswerDto({
    required AnswerResultDto result,
    required TestSessionDto session,
  }) = _SessionAnswerDto;

  const SessionAnswerDto._();

  factory SessionAnswerDto.fromJson(Map<String, dynamic> json) =>
      _$SessionAnswerDtoFromJson(json);

  SessionAnswer toDomain() =>
      SessionAnswer(result: result.toDomain(), session: session.toDomain());
}
