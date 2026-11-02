import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// Reanuda una sesión en pausa. [resumedAt]: cuándo se reanudó en el móvil
/// (si no había conexión, el aviso llega más tarde; el servidor lo acota).
abstract interface class ResumeSessionUseCaseContract {
  Future<AppResult<TrainingSession>> call(
    String sessionId, {
    DateTime? resumedAt,
  });
}

class ResumeSessionUseCase implements ResumeSessionUseCaseContract {
  const ResumeSessionUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(
    String sessionId, {
    DateTime? resumedAt,
  }) => _repository.resumeSession(sessionId, resumedAt: resumedAt);
}
