import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Borra un bloque.
abstract interface class DeleteBlockUseCaseContract {
  Future<AppResult<Unit>> call(String blockId);
}

class DeleteBlockUseCase implements DeleteBlockUseCaseContract {
  const DeleteBlockUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String blockId) =>
      _repository.deleteBlock(blockId);
}
