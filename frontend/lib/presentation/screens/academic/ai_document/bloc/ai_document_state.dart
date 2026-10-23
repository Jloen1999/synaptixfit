part of 'ai_document_bloc.dart';

@freezed
abstract class AiDocumentState with _$AiDocumentState {
  const factory AiDocumentState({
    @Default(StudySourceType.note) StudySourceType sourceType,
    @Default('') String sourceId,
    @Default(AiDocumentType.summary) AiDocumentType type,
    @Default(true) bool loading,
    AppError? error,
    StudyDocument? document,
    @Default(false) bool regenerating,
    AppError? actionError,
  }) = _AiDocumentState;
}
