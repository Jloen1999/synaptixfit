import '../../models/planner/block_draft.dart';
import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Crea un bloque y devuelve los solapes como aviso.
abstract interface class CreateBlockUseCaseContract {
  Future<AppResult<BlockChange>> call(BlockDraft draft);
}

class CreateBlockUseCase implements CreateBlockUseCaseContract {
  const CreateBlockUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<BlockChange>> call(BlockDraft draft) =>
      _repository.createBlock(draft);
}
