import '../../enums/training_enums.dart';
import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/routine_repository_contract.dart';

/// Añade una semana al final de la rutina.
abstract interface class AddRoutineWeekUseCaseContract {
  Future<AppResult<Routine>> call(
    String routineId, {
    String? name,
    WeekType? type,
  });
}

class AddRoutineWeekUseCase implements AddRoutineWeekUseCaseContract {
  const AddRoutineWeekUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Routine>> call(
    String routineId, {
    String? name,
    WeekType? type,
  }) => _repository.addWeek(routineId, name: name, type: type);
}
