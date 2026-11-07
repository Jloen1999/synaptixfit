import '../../models/result/app_result.dart';
import '../../repositories/run_repository_contract.dart';

/// Si el GPS del móvil está encendido.
abstract interface class IsLocationServiceEnabledUseCaseContract {
  Future<AppResult<bool>> call();
}

class IsLocationServiceEnabledUseCase
    implements IsLocationServiceEnabledUseCaseContract {
  const IsLocationServiceEnabledUseCase(this._repository);

  final RunTrackerRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call() => _repository.locationServiceEnabled();
}
