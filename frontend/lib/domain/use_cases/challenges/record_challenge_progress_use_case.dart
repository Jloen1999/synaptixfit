import '../../models/challenges/challenge_outcome.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Registra progreso manual (0,01-100) en un reto o tarea.
abstract interface class RecordChallengeProgressUseCaseContract {
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId, {
    String? milestoneId,
    required double amount,
  });
}

class RecordChallengeProgressUseCase
    implements RecordChallengeProgressUseCaseContract {
  const RecordChallengeProgressUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId, {
    String? milestoneId,
    required double amount,
  }) => _repository.recordProgress(
    challengeId,
    milestoneId: milestoneId,
    amount: amount,
  );
}
