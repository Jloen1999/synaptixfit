import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Rutina completa con semanas, días y ejercicios.
abstract interface class GetRoutineUseCaseContract {
  Future<AppResult<Routine>> call(String routineId);
}

class GetRoutineUseCase implements GetRoutineUseCaseContract {
  const GetRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId) =>
      _repository.getRoutine(routineId);
}
