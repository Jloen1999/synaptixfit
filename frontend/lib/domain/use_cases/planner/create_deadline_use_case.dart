import '../../models/planner/deadline.dart';
import '../../models/result/app_result.dart';
import '../../repositories/deadline_repository_contract.dart';

/// Crea una entrega o examen.
abstract interface class CreateDeadlineUseCaseContract {
  Future<AppResult<Deadline>> call(DeadlineDraft draft);
}

class CreateDeadlineUseCase implements CreateDeadlineUseCaseContract {
  const CreateDeadlineUseCase(this._repository);

  final DeadlineRepositoryContract _repository;

  @override
  Future<AppResult<Deadline>> call(DeadlineDraft draft) =>
      _repository.createDeadline(draft);
}
