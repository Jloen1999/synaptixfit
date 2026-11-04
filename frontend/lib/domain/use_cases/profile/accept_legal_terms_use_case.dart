import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/legal_repository_contract.dart';

/// Acepta la versión [version] de la política de privacidad y las condiciones:
/// la que la persona ha visto. Si mientras tanto ha cambiado, el servidor
/// responde `LEGAL_VERSION_OUTDATED` y hay que volver a leerla.
abstract interface class AcceptLegalTermsUseCaseContract {
  Future<AppResult<Unit>> call(String version);
}

class AcceptLegalTermsUseCase implements AcceptLegalTermsUseCaseContract {
  const AcceptLegalTermsUseCase(this._repository);

  final LegalRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String version) => _repository.accept(version);
}
