import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Cambia los parámetros de un ejercicio planificado.
abstract interface class UpdateRoutineExerciseUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId,
    String plannedExerciseId,
    ExerciseParameters parameters,
  );
}

class UpdateRoutineExerciseUseCase
    implements UpdateRoutineExerciseUseCaseContract {
  const UpdateRoutineExerciseUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String plannedExerciseId,
    ExerciseParameters parameters,
  ) => _repository.updateExercise(routineId, plannedExerciseId, parameters);
}
