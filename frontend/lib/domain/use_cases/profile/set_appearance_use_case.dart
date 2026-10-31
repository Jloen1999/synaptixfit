import '../../enums/appearance_mode.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/appearance_repository_contract.dart';

/// Guarda la apariencia elegida en este dispositivo.
abstract interface class SetAppearanceUseCaseContract {
  Future<AppResult<Unit>> call(AppearanceMode mode);
}

class SetAppearanceUseCase implements SetAppearanceUseCaseContract {
  const SetAppearanceUseCase(this._repository);

  final AppearanceRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(AppearanceMode mode) =>
      _repository.setMode(mode);
}
