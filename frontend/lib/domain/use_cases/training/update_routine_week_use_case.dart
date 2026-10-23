import '../../enums/training_enums.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Renombra o cambia el tipo de una semana.
abstract interface class UpdateRoutineWeekUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId,
    String weekId, {
    String? name,
    WeekType? type,
  });
}

class UpdateRoutineWeekUseCase implements UpdateRoutineWeekUseCaseContract {
  const UpdateRoutineWeekUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId,
    String weekId, {
    String? name,
    WeekType? type,
  }) => _repository.updateWeek(routineId, weekId, name: name, type: type);
}
