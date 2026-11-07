import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Posición actual para «Estás aquí» (nula si no se puede).
abstract interface class GetCurrentPositionUseCaseContract {
  Future<AppResult<RunFix?>> call();
}

class GetCurrentPositionUseCase implements GetCurrentPositionUseCaseContract {
  const GetCurrentPositionUseCase(this._repository);

  final RunTrackerRepositoryContract _repository;

  @override
  Future<AppResult<RunFix?>> call() => _repository.currentPosition();
}
