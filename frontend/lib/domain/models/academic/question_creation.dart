import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/question_creation_enums.dart';
import '../../enums/question_type.dart';

part 'question_creation.freezed.dart';

/// Pregunta que ya traía escrita el apunte o archivo (ADR 0058). `type` es
/// nulo si es de respuesta larga (no se puede corregir sola).
@freezed
abstract class DocumentQuestion with _$DocumentQuestion {
  const factory DocumentQuestion({
    QuestionType? type,
    required String statement,
    @Default(<String>[]) List<String> options,
    @Default(<String>[]) List<String> correctAnswers,
    String? explanation,
    required DocumentQuestionStatus status,
  }) = _DocumentQuestion;

  const DocumentQuestion._();

  bool get usable => type != null && status.usable && correctAnswers.isNotEmpty;
}

/// Lo que se leyó del documento; `complete` es falso si no se pudieron leer
/// todas.
@freezed
abstract class DocumentQuestionScan with _$DocumentQuestionScan {
  const factory DocumentQuestionScan({
    @Default(<DocumentQuestion>[]) List<DocumentQuestion> questions,
    @Default(true) bool complete,
  }) = _DocumentQuestionScan;
}

/// Lo que se pide al crear preguntas: las del documento ya revisadas y
/// cuántas nuevas.
@freezed
abstract class CreateQuestionsRequest with _$CreateQuestionsRequest {
  const factory CreateQuestionsRequest({
    required QuestionFormat format,
    required int newQuestions,
    required BankUpdateMode mode,
    @Default(<DocumentQuestion>[]) List<DocumentQuestion> documentQuestions,
  }) = _CreateQuestionsRequest;
}

/// Cuántas preguntas se piden en la hoja: de 5 a 30, de 5 en 5 (el servidor
/// no acepta más de 30 nuevas de una vez, ADR 0058).
abstract final class QuestionCount {
  static const min = 5;
  static const max = 30;
  static const step = 5;
  static const initial = 10;

  /// Nuevas que hay que crear para llegar a [total] con [fromDocument] del
  /// documento: con «Usar solo esas», ninguna.
  static int newQuestions({
    required DocumentQuestionUse use,
    required int total,
    required int fromDocument,
  }) => switch (use) {
    DocumentQuestionUse.only => 0,
    DocumentQuestionUse.none => total,
    DocumentQuestionUse.mix => math.max(0, total - fromDocument),
  };
}
