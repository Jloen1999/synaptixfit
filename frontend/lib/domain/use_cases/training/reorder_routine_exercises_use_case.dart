import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Cambia el orden de los ejercicios de un día.
abstract interface class ReorderRoutineExercisesUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId,
    String dayId,
    List<String> plannedExerciseIds,
  );
}

class ReorderRoutineExercisesUseCase
    implements ReorderRoutineExercisesUseCaseContract {
  const ReorderRoutineExercisesUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String dayId,
    List<String> plannedExerciseIds,
  ) => _repository.reorderExercises(routineId, dayId, plannedExerciseIds);
}
