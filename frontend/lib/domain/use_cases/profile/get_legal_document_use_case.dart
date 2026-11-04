import '../../enums/legal_document_kind.dart';
import '../../models/profile/legal_document.dart';
import '../../models/result/app_result.dart';
import '../../repositories/legal_repository_contract.dart';

/// Política de privacidad, condiciones o cómo borrar la cuenta, en el idioma
/// de la app. Se puede leer sin haber iniciado sesión.
abstract interface class GetLegalDocumentUseCaseContract {
  Future<AppResult<LegalDocument>> call(
    LegalDocumentKind kind, {
    required String language,
  });
}

class GetLegalDocumentUseCase implements GetLegalDocumentUseCaseContract {
  const GetLegalDocumentUseCase(this._repository);

  final LegalRepositoryContract _repository;

  @override
  Future<AppResult<LegalDocument>> call(
    LegalDocumentKind kind, {
    required String language,
  }) => _repository.document(kind, language: language);
}
