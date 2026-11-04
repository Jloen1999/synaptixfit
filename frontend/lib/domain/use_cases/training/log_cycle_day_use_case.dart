import '../../models/result/app_result.dart';
import '../../models/training/cycle.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Apunta o corrige un día del ciclo.
abstract interface class LogCycleDayUseCaseContract {
  Future<AppResult<CycleOverview>> call(CycleDay day);
}

class LogCycleDayUseCase implements LogCycleDayUseCaseContract {
  const LogCycleDayUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<CycleOverview>> call(CycleDay day) =>
      _repository.logCycleDay(day);
}
