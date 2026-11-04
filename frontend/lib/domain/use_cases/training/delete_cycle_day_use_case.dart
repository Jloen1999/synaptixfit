import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Borra lo apuntado un día del ciclo.
abstract interface class DeleteCycleDayUseCaseContract {
  Future<AppResult<Unit>> call(DateTime date);
}

class DeleteCycleDayUseCase implements DeleteCycleDayUseCaseContract {
  const DeleteCycleDayUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(DateTime date) =>
      _repository.deleteCycleDay(date);
}
