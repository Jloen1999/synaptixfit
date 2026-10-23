import '../../models/planner/deadline.dart';
import '../../models/result/app_result.dart';
import '../../repositories/deadline_repository_contract.dart';

/// Marca o desmarca una entrega como completada (da o quita XP).
abstract interface class SetDeadlineCompletionUseCaseContract {
  Future<AppResult<DeadlineCompletion>> call(
    String id, {
    required bool completed,
  });
}

class SetDeadlineCompletionUseCase
    implements SetDeadlineCompletionUseCaseContract {
  const SetDeadlineCompletionUseCase(this._repository);

  final DeadlineRepositoryContract _repository;

  @override
  Future<AppResult<DeadlineCompletion>> call(
    String id, {
    required bool completed,
  }) => _repository.setDeadlineCompletion(id, completed: completed);
}
