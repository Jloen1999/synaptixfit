import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Finaliza una sesión: calorías, experiencia y sugerencias.
abstract interface class FinishSessionUseCaseContract {
  Future<AppResult<FinishSessionResult>> call(
    String sessionId, {
    required int durationSeconds,
    required int rpe,
    Map<String, int> realDurations = const {},
    List<SetRecord> sets = const [],
  });
}

class FinishSessionUseCase implements FinishSessionUseCaseContract {
  const FinishSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<FinishSessionResult>> call(
    String sessionId, {
    required int durationSeconds,
    required int rpe,
    Map<String, int> realDurations = const {},
    List<SetRecord> sets = const [],
  }) => _repository.finishSession(
    sessionId,
    durationSeconds: durationSeconds,
    rpe: rpe,
    realDurations: realDurations,
    sets: sets,
  );
}
