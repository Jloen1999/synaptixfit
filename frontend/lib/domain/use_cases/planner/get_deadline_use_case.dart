import '../../models/planner/deadline.dart';
import '../../models/result/app_result.dart';
import '../../repositories/deadline_repository_contract.dart';

/// Una entrega o examen por su id (para abrirla desde su aviso).
abstract interface class GetDeadlineUseCaseContract {
  Future<AppResult<Deadline>> call(String id);
}

class GetDeadlineUseCase implements GetDeadlineUseCaseContract {
  const GetDeadlineUseCase(this._repository);

  final DeadlineRepositoryContract _repository;

  @override
  Future<AppResult<Deadline>> call(String id) => _repository.getDeadline(id);
}
