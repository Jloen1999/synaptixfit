import '../../models/result/app_result.dart';
import '../../repositories/routine_repository_contract.dart';

/// Hasta cuándo se comparte la rutina por enlace; `null` si no (ADR 0043).
abstract interface class GetRoutineShareStatusUseCaseContract {
  Future<AppResult<DateTime?>> call(String routineId);
}

class GetRoutineShareStatusUseCase
    implements GetRoutineShareStatusUseCaseContract {
  const GetRoutineShareStatusUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<DateTime?>> call(String routineId) =>
      _repository.shareStatus(routineId);
}
