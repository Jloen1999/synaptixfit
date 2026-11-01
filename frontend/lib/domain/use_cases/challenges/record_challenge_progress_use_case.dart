import '../../models/challenges/challenge_outcome.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Fija el progreso manual de un reto o tarea: valor absoluto 0-100
/// («¿cuánto llevas?»), no una cantidad que se suma.
abstract interface class RecordChallengeProgressUseCaseContract {
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId, {
    String? milestoneId,
    required double value,
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
    required double value,
  }) => _repository.recordProgress(
    challengeId,
    milestoneId: milestoneId,
    value: value,
  );
}
