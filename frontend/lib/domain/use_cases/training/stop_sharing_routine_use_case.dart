import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/routine_repository_contract.dart';

/// «Dejar de compartir»: los enlaces de la rutina dejan de valer (ADR 0043).
abstract interface class StopSharingRoutineUseCaseContract {
  Future<AppResult<Unit>> call(String routineId);
}

class StopSharingRoutineUseCase implements StopSharingRoutineUseCaseContract {
  const StopSharingRoutineUseCase(this._repository);

  final RoutineRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String routineId) =>
      _repository.stopSharing(routineId);
}
