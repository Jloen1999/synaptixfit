import '../../models/result/app_result.dart';
import '../../repositories/account_privacy_repository_contract.dart';

/// Exporta los datos del usuario a un JSON (false si cancela el guardado).
abstract interface class ExportMyDataUseCaseContract {
  Future<AppResult<bool>> call();
}

class ExportMyDataUseCase implements ExportMyDataUseCaseContract {
  const ExportMyDataUseCase(this._repository);

  final AccountPrivacyRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call() => _repository.exportMyData();
}
