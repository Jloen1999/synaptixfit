import '../../models/planner/block_draft.dart';
import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Edita los datos de un bloque (no su horario).
abstract interface class UpdateBlockUseCaseContract {
  Future<AppResult<CalendarBlock>> call(String blockId, BlockDraft draft);
}

class UpdateBlockUseCase implements UpdateBlockUseCaseContract {
  const UpdateBlockUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<CalendarBlock>> call(String blockId, BlockDraft draft) =>
      _repository.updateBlock(blockId, draft);
}
