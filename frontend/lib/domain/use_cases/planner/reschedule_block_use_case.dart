import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Mueve o redimensiona un bloque.
abstract interface class RescheduleBlockUseCaseContract {
  Future<AppResult<BlockChange>> call(
    String blockId, {
    required DateTime start,
    required DateTime end,
  });
}

class RescheduleBlockUseCase implements RescheduleBlockUseCaseContract {
  const RescheduleBlockUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<BlockChange>> call(
    String blockId, {
    required DateTime start,
    required DateTime end,
  }) => _repository.rescheduleBlock(blockId, start: start, end: end);
}
