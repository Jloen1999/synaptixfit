import '../../models/planner/calendar_block.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Marca o desmarca un bloque como completado (da o quita XP). [effort]
/// (1-10) es el esfuerzo de un bloque de deporte sin rutina, para su carga física.
abstract interface class SetBlockCompletionUseCaseContract {
  Future<AppResult<BlockCompletion>> call(
    String blockId, {
    required bool completed,
    int? effort,
  });
}

class SetBlockCompletionUseCase implements SetBlockCompletionUseCaseContract {
  const SetBlockCompletionUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<BlockCompletion>> call(
    String blockId, {
    required bool completed,
    int? effort,
  }) => _repository.setBlockCompletion(
    blockId,
    completed: completed,
    effort: effort,
  );
}
