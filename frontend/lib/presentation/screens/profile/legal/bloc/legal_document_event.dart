part of 'legal_document_bloc.dart';

@freezed
sealed class LegalDocumentEvent with _$LegalDocumentEvent {
  /// Carga (o vuelve a cargar con «Reintentar») el documento.
  const factory LegalDocumentEvent.started({
    required LegalDocumentKind kind,
    required String language,
  }) = LegalDocumentStarted;
}
