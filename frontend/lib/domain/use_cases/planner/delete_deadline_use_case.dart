import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/deadline_repository_contract.dart';

/// Borra una entrega o examen.
abstract interface class DeleteDeadlineUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

class DeleteDeadlineUseCase implements DeleteDeadlineUseCaseContract {
  const DeleteDeadlineUseCase(this._repository);

  final DeadlineRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.deleteDeadline(id);
}
