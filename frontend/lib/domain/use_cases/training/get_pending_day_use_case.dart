import '../../models/result/app_result.dart';
import '../../models/training/routine.dart';
import '../../repositories/training_repository_contract.dart';

/// Próximo día de entrenamiento pendiente (o null).
abstract interface class GetPendingDayUseCaseContract {
  Future<AppResult<PendingDay?>> call();
}

class GetPendingDayUseCase implements GetPendingDayUseCaseContract {
  const GetPendingDayUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<PendingDay?>> call() => _repository.getPendingDay();
}
