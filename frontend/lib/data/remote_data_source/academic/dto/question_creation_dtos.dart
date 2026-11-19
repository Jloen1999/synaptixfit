import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/question_creation_enums.dart';
import '../../../../domain/enums/question_type.dart';
import '../../../../domain/models/academic/question_creation.dart';

part 'question_creation_dtos.freezed.dart';
part 'question_creation_dtos.g.dart';

/// Pregunta que ya traía el documento (`POST …/document-questions`).
@freezed
abstract class DocumentQuestionDto with _$DocumentQuestionDto {
  const factory DocumentQuestionDto({
    String? type,
    @Default('') String statement,
    @Default(<String>[]) List<String> options,
    @Default(<String>[]) List<String> correctAnswers,
    String? explanation,
    String? status,
  }) = _DocumentQuestionDto;

  const DocumentQuestionDto._();

  factory DocumentQuestionDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentQuestionDtoFromJson(json);

  DocumentQuestion toDomain() => DocumentQuestion(
    type: type == null ? null : QuestionType.fromApi(type),
    statement: statement,
    options: options,
    correctAnswers: correctAnswers,
    explanation: explanation,
    status: type == null
        ? DocumentQuestionStatus.longAnswer
        : DocumentQuestionStatus.fromApi(status),
  );
}

/// Resultado de leer las preguntas del documento.
@freezed
abstract class DocumentQuestionScanDto with _$DocumentQuestionScanDto {
  const factory DocumentQuestionScanDto({
    @Default(<DocumentQuestionDto>[]) List<DocumentQuestionDto> questions,
    @Default(true) bool complete,
  }) = _DocumentQuestionScanDto;

  const DocumentQuestionScanDto._();

  factory DocumentQuestionScanDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentQuestionScanDtoFromJson(json);

  DocumentQuestionScan toDomain() => DocumentQuestionScan(
    questions: [for (final q in questions) q.toDomain()],
    complete: complete,
  );
}

/// Cuerpo de `POST …/question-bank` (ADR 0058).
class CreateQuestionsRequestDto {
  const CreateQuestionsRequestDto._(this._request);

  factory CreateQuestionsRequestDto.from(CreateQuestionsRequest request) =>
      CreateQuestionsRequestDto._(request);

  final CreateQuestionsRequest _request;

  Map<String, dynamic> toJson() => {
    'format': _request.format.apiValue,
    'newQuestions': _request.newQuestions,
    'mode': _request.mode.apiValue,
    'documentQuestions': [
      for (final q in _request.documentQuestions)
        if (q.type != null)
          {
            'type': q.type!.apiValue,
            'statement': q.statement,
            'options': q.options,
            'correctAnswers': q.correctAnswers,
            'explanation': ?q.explanation,
          },
    ],
  };
}
