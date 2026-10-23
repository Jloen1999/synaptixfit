import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/ai_document_type.dart';
import '../../../../domain/enums/artifact_kind.dart';
import '../../../../domain/enums/question_type.dart';
import '../../../../domain/enums/study_source_type.dart';
import '../../../../domain/models/academic/mind_map.dart';
import '../../../../domain/models/academic/study_artifact.dart';
import '../../../../domain/models/academic/study_document.dart';

part 'study_dtos.freezed.dart';
part 'study_dtos.g.dart';

@freezed
abstract class MindMapDto with _$MindMapDto {
  const factory MindMapDto({
    String? central,
    @Default(<MindMapNodeDto>[]) List<MindMapNodeDto> branches,
  }) = _MindMapDto;

  const MindMapDto._();

  factory MindMapDto.fromJson(Map<String, dynamic> json) =>
      _$MindMapDtoFromJson(json);

  MindMap toDomain() => MindMap(
    central: central ?? '',
    branches: branches.map((b) => b.toDomain()).toList(),
  );

  /// Cuerpo de la petición a partir del modelo de dominio.
  static Map<String, dynamic> body(MindMap map) => {
    'central': map.central,
    'branches': map.branches.map(MindMapNodeDto.body).toList(),
  };
}

@freezed
abstract class MindMapNodeDto with _$MindMapNodeDto {
  const factory MindMapNodeDto({
    @Default('') String title,
    @Default(<MindMapNodeDto>[]) List<MindMapNodeDto> children,
  }) = _MindMapNodeDto;

  const MindMapNodeDto._();

  factory MindMapNodeDto.fromJson(Map<String, dynamic> json) =>
      _$MindMapNodeDtoFromJson(json);

  MindMapNode toDomain() => MindMapNode(
    title: title,
    children: children.map((c) => c.toDomain()).toList(),
  );

  static Map<String, dynamic> body(MindMapNode node) => {
    'title': node.title,
    'children': node.children.map(body).toList(),
  };
}

@freezed
abstract class StudyDocumentDto with _$StudyDocumentDto {
  const factory StudyDocumentDto({
    required String id,
    String? sourceType,
    required String sourceId,
    String? type,
    String? subjectId,
    String? sourceTitle,
    String? markdown,
    MindMapDto? mindMap,
    String? materialId,
    String? questionBankId,
    int? questionCount,
    DateTime? updatedAt,
  }) = _StudyDocumentDto;

  const StudyDocumentDto._();

  factory StudyDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$StudyDocumentDtoFromJson(json);

  StudyDocument toDomain() => StudyDocument(
    id: id,
    sourceType: StudySourceType.fromApi(sourceType),
    sourceId: sourceId,
    type: AiDocumentType.fromApi(type),
    subjectId: subjectId,
    sourceTitle: sourceTitle,
    markdown: markdown,
    mindMap: mindMap?.toDomain(),
    materialId: materialId,
    questionBankId: questionBankId,
    questionCount: questionCount,
    updatedAt: updatedAt?.toLocal(),
  );
}

@freezed
abstract class DocumentAvailabilityDto with _$DocumentAvailabilityDto {
  const factory DocumentAvailabilityDto({
    @Default(false) bool summary,
    @Default(false) bool mindMap,
    @Default(false) bool practice,
  }) = _DocumentAvailabilityDto;

  const DocumentAvailabilityDto._();

  factory DocumentAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentAvailabilityDtoFromJson(json);

  DocumentAvailability toDomain() => DocumentAvailability(
    summary: summary,
    mindMap: mindMap,
    practice: practice,
  );
}

@freezed
abstract class FlashcardDto with _$FlashcardDto {
  const factory FlashcardDto({
    @Default('') String question,
    @Default('') String answer,
  }) = _FlashcardDto;

  const FlashcardDto._();

  factory FlashcardDto.fromJson(Map<String, dynamic> json) =>
      _$FlashcardDtoFromJson(json);

  Flashcard toDomain() => Flashcard(question: question, answer: answer);
}

@freezed
abstract class QuestionDraftDto with _$QuestionDraftDto {
  const factory QuestionDraftDto({
    String? type,
    @Default('') String statement,
    @Default(<String>[]) List<String> options,
    @Default('') String correctAnswer,
    String? explanation,
  }) = _QuestionDraftDto;

  const QuestionDraftDto._();

  factory QuestionDraftDto.fromJson(Map<String, dynamic> json) =>
      _$QuestionDraftDtoFromJson(json);

  QuestionDraft toDomain() => QuestionDraft(
    type: QuestionType.fromApi(type),
    statement: statement,
    options: options,
    correctAnswer: correctAnswer,
    explanation: explanation,
  );

  static Map<String, dynamic> body(QuestionDraft q) => {
    'type': q.type.apiValue,
    'statement': q.statement,
    'options': q.options,
    'correctAnswer': q.correctAnswer,
    'explanation': ?q.explanation,
  };
}

@freezed
abstract class ArtifactDto with _$ArtifactDto {
  const factory ArtifactDto({
    String? kind,
    @Default('') String title,
    String? markdown,
    MindMapDto? mindMap,
    @Default(<FlashcardDto>[]) List<FlashcardDto> flashcards,
    @Default(<QuestionDraftDto>[]) List<QuestionDraftDto> questions,
  }) = _ArtifactDto;

  const ArtifactDto._();

  factory ArtifactDto.fromJson(Map<String, dynamic> json) =>
      _$ArtifactDtoFromJson(json);

  StudyArtifact toDomain() => StudyArtifact(
    kind: ArtifactKind.fromApi(kind),
    title: title,
    markdown: markdown,
    mindMap: mindMap?.toDomain(),
    flashcards: flashcards.map((f) => f.toDomain()).toList(),
    questions: questions.map((q) => q.toDomain()).toList(),
  );
}

@freezed
abstract class SavedQuizDto with _$SavedQuizDto {
  const factory SavedQuizDto({
    required String noteId,
    required String materialId,
    required String questionBankId,
    @Default(0) int questionCount,
  }) = _SavedQuizDto;

  const SavedQuizDto._();

  factory SavedQuizDto.fromJson(Map<String, dynamic> json) =>
      _$SavedQuizDtoFromJson(json);

  SavedQuiz toDomain() => SavedQuiz(
    noteId: noteId,
    materialId: materialId,
    questionBankId: questionBankId,
    questionCount: questionCount,
  );
}
