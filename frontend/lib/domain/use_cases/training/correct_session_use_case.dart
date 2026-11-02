import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Corrige el RPE y la duración de una sesión de otro día (no se desmarca).
abstract interface class CorrectSessionUseCaseContract {
  Future<AppResult<TrainingSession>> call(
    String sessionId, {
    required int rpe,
    required int durationMinutes,
  });
}

class CorrectSessionUseCase implements CorrectSessionUseCaseContract {
  const CorrectSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(
    String sessionId, {
    required int rpe,
    required int durationMinutes,
  }) => _repository.correctSession(
    sessionId,
    rpe: rpe,
    durationMinutes: durationMinutes,
  );
}
