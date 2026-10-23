import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Añade un ejercicio del catálogo a un día.
abstract interface class AddRoutineExerciseUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId,
    String dayId, {
    required String exerciseId,
    required ExerciseParameters parameters,
  });
}

class AddRoutineExerciseUseCase implements AddRoutineExerciseUseCaseContract {
  const AddRoutineExerciseUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String dayId, {
    required String exerciseId,
    required ExerciseParameters parameters,
  }) => _repository.addExercise(
    routineId,
    dayId,
    exerciseId: exerciseId,
    parameters: parameters,
  );
}
