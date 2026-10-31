import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Lleva un bloque (p. ej. uno que se quedó sin hacer) al primer hueco libre.
abstract interface class RescheduleBlockToNextFreeSlotUseCaseContract {
  Future<AppResult<BlockChange>> call(String blockId);
}

class RescheduleBlockToNextFreeSlotUseCase
    implements RescheduleBlockToNextFreeSlotUseCaseContract {
  const RescheduleBlockToNextFreeSlotUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<BlockChange>> call(String blockId) =>
      _repository.rescheduleToNextFreeSlot(blockId);
}
