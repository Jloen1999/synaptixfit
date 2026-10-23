import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Añade un día a una semana.
abstract interface class AddRoutineDayUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId,
    String weekId, {
    required int dayNumber,
    String? name,
  });
}

class AddRoutineDayUseCase implements AddRoutineDayUseCaseContract {
  const AddRoutineDayUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String weekId, {
    required int dayNumber,
    String? name,
  }) => _repository.addDay(routineId, weekId, dayNumber: dayNumber, name: name);
}
