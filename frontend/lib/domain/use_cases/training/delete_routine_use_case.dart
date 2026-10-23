import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/routine_repository_contract.dart';

/// Elimina una rutina propia.
abstract interface class DeleteRoutineUseCaseContract {
  Future<AppResult<Unit>> call(String routineId);
}

class DeleteRoutineUseCase implements DeleteRoutineUseCaseContract {
  const DeleteRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String routineId) =>
      _repository.deleteRoutine(routineId);
}
