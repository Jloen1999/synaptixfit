import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Empieza (o recupera) una sesión de un día o libre.
abstract interface class StartSessionUseCaseContract {
  Future<AppResult<TrainingSession>> call({String? routineId, String? dayId});
}

class StartSessionUseCase implements StartSessionUseCaseContract {
  const StartSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call({String? routineId, String? dayId}) =>
      _repository.startSession(routineId: routineId, dayId: dayId);
}
