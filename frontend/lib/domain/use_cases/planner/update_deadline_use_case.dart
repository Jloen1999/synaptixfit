import '../../models/planner/deadline.dart';
import '../../models/result/app_result.dart';
import '../../repositories/deadline_repository_contract.dart';

/// Edita una entrega o examen.
abstract interface class UpdateDeadlineUseCaseContract {
  Future<AppResult<Deadline>> call(String id, DeadlineDraft draft);
}

class UpdateDeadlineUseCase implements UpdateDeadlineUseCaseContract {
  const UpdateDeadlineUseCase(this._repository);

  final DeadlineRepositoryContract _repository;

  @override
  Future<AppResult<Deadline>> call(String id, DeadlineDraft draft) =>
      _repository.updateDeadline(id, draft);
}
