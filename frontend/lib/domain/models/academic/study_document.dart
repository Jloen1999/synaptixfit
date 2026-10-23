import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/ai_document_type.dart';
import '../../enums/study_source_type.dart';
import 'mind_map.dart';

part 'study_document.freezed.dart';

/// Documento de IA guardado sobre un apunte o archivo.
@freezed
abstract class StudyDocument with _$StudyDocument {
  const factory StudyDocument({
    required String id,
    required StudySourceType sourceType,
    required String sourceId,
    required AiDocumentType type,
    String? subjectId,
    String? sourceTitle,
    String? markdown,
    MindMap? mindMap,
    String? materialId,
    String? questionBankId,
    int? questionCount,
    DateTime? updatedAt,
  }) = _StudyDocument;
}

/// Qué documentos de IA tiene ya guardados una fuente.
@freezed
abstract class DocumentAvailability with _$DocumentAvailability {
  const factory DocumentAvailability({
    required bool summary,
    required bool mindMap,
    required bool practice,
  }) = _DocumentAvailability;

  const DocumentAvailability._();

  static const none = DocumentAvailability(
    summary: false,
    mindMap: false,
    practice: false,
  );

  bool has(AiDocumentType type) => switch (type) {
    AiDocumentType.summary => summary,
    AiDocumentType.mindMap => mindMap,
    AiDocumentType.practice => practice,
    AiDocumentType.teachingGuide => false,
  };

  bool get any => summary || mindMap || practice;
}
