import '../enums/legal_document_kind.dart';
import '../models/profile/legal_document.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Textos legales públicos y la aceptación de la política (ADR 0034).
abstract interface class LegalRepositoryContract {
  /// Texto en [language]; el servidor usa el español si no lo tiene.
  Future<AppResult<LegalDocument>> document(
    LegalDocumentKind kind, {
    required String language,
  });

  Future<AppResult<LegalAcceptance>> acceptance();

  Future<AppResult<Unit>> accept(String version);
}
