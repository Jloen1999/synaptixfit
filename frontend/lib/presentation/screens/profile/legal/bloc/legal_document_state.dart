part of 'legal_document_bloc.dart';

@freezed
abstract class LegalDocumentState with _$LegalDocumentState {
  const factory LegalDocumentState({
    @Default(true) bool loading,
    LegalDocument? document,
    AppError? error,
  }) = _LegalDocumentState;
}
