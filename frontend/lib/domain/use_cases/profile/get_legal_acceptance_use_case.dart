import '../../models/profile/legal_document.dart';
import '../../models/result/app_result.dart';
import '../../repositories/legal_repository_contract.dart';

/// Si la persona tiene que aceptar la versión vigente de la política (lo
/// decide el servidor comparando versiones).
abstract interface class GetLegalAcceptanceUseCaseContract {
  Future<AppResult<LegalAcceptance>> call();
}

class GetLegalAcceptanceUseCase implements GetLegalAcceptanceUseCaseContract {
  const GetLegalAcceptanceUseCase(this._repository);

  final LegalRepositoryContract _repository;

  @override
  Future<AppResult<LegalAcceptance>> call() => _repository.acceptance();
}
