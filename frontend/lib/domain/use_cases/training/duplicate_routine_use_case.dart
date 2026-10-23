import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Duplica una rutina propia.
abstract interface class DuplicateRoutineUseCaseContract {
  Future<AppResult<Routine>> call(String routineId, {String? name});
}

class DuplicateRoutineUseCase implements DuplicateRoutineUseCaseContract {
  const DuplicateRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(String routineId, {String? name}) =>
      _repository.duplicateRoutine(routineId, name: name);
}
