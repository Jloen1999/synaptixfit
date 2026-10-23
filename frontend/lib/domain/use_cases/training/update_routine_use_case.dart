import '../../enums/training_enums.dart';
import '../../enums/visibility.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Edita los datos generales de una rutina.
abstract interface class UpdateRoutineUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId, {
    String? name,
    String? description,
    Visibility? visibility,
    TrainingGoal? goal,
    DateTime? startDate,
    bool clearStartDate = false,
  });
}

class UpdateRoutineUseCase implements UpdateRoutineUseCaseContract {
  const UpdateRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId, {
    String? name,
    String? description,
    Visibility? visibility,
    TrainingGoal? goal,
    DateTime? startDate,
    bool clearStartDate = false,
  }) => _repository.updateRoutine(
    routineId,
    name: name,
    description: description,
    visibility: visibility,
    goal: goal,
    startDate: startDate,
    clearStartDate: clearStartDate,
  );
}
