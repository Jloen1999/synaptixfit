import '../../models/challenges/challenge_draft.dart';
import '../../models/challenges/challenge_draft_validator.dart';
import '../../models/challenges/challenge_outcome.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Reemplaza la lista de tareas de un reto (conserva el progreso de las que
/// llevan `id`) tras validar pesos y dependencias.
abstract interface class ReplaceMilestonesUseCaseContract {
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId,
    List<MilestoneDraft> milestones,
  );
}

class ReplaceMilestonesUseCase implements ReplaceMilestonesUseCaseContract {
  const ReplaceMilestonesUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengeOutcome>> call(
    String challengeId,
    List<MilestoneDraft> milestones,
  ) async {
    final issue = ChallengeDraftValidator.validateMilestones(milestones);
    if (issue != null) return Failure(issue.asError);
    return _repository.replaceMilestones(challengeId, milestones);
  }
}
