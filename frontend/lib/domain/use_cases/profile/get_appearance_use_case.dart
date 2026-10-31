import '../../enums/appearance_mode.dart';
import '../../models/result/app_result.dart';
import '../../repositories/appearance_repository_contract.dart';

/// Apariencia elegida en este dispositivo (oscura por defecto).
abstract interface class GetAppearanceUseCaseContract {
  Future<AppResult<AppearanceMode>> call();
}

class GetAppearanceUseCase implements GetAppearanceUseCaseContract {
  const GetAppearanceUseCase(this._repository);

  final AppearanceRepositoryContract _repository;

  @override
  Future<AppResult<AppearanceMode>> call() => _repository.getMode();
}
