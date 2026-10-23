part of 'ai_document_bloc.dart';

@freezed
sealed class AiDocumentEvent with _$AiDocumentEvent {
  const factory AiDocumentEvent.started({
    required StudySourceType sourceType,
    required String sourceId,
    required AiDocumentType type,
  }) = AiDocumentStarted;

  /// Vuelve a generar el documento y sobrescribe el guardado.
  const factory AiDocumentEvent.regenerated() = AiDocumentRegenerated;
}
