import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/question_standing.dart';
import 'quiz.dart';

part 'subject_questions.freezed.dart';

/// Todas las preguntas de una asignatura para «Practicar» (ADR 0063), en el
/// orden en que vuelven (lo decide el servidor). [toReview]: cuántas tocan
/// repasar.
@freezed
abstract class SubjectQuestions with _$SubjectQuestions {
  const factory SubjectQuestions({
    /// Nombre de la asignatura, para el título de la pantalla.
    @Default('') String subjectName,
    @Default(0) int total,
    @Default(0) int toReview,
    @Default(<SubjectQuestion>[]) List<SubjectQuestion> questions,
  }) = _SubjectQuestions;
}

/// Pregunta con el apunte o archivo del que sale y cómo va.
@freezed
abstract class SubjectQuestion with _$SubjectQuestion {
  const factory SubjectQuestion({
    required Question question,
    required String materialId,
    @Default('') String materialTitle,
    required QuestionStanding standing,
    DateTime? lastAnsweredAt,
  }) = _SubjectQuestion;
}
