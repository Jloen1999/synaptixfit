import '../../models/result/app_result.dart';
import '../../models/training/cycle.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Resumen del seguimiento del ciclo (opcional).
abstract interface class GetCycleOverviewUseCaseContract {
  Future<AppResult<CycleOverview>> call();
}

class GetCycleOverviewUseCase implements GetCycleOverviewUseCaseContract {
  const GetCycleOverviewUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<CycleOverview>> call() => _repository.getCycle();
}
