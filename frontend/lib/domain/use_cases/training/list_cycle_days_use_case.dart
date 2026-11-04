import '../../models/result/app_result.dart';
import '../../models/training/cycle.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Días apuntados del ciclo entre dos fechas (calendario).
abstract interface class ListCycleDaysUseCaseContract {
  Future<AppResult<List<CycleDay>>> call(DateTime from, DateTime to);
}

class ListCycleDaysUseCase implements ListCycleDaysUseCaseContract {
  const ListCycleDaysUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<List<CycleDay>>> call(DateTime from, DateTime to) =>
      _repository.listCycleDays(from, to);
}
