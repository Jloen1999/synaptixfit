import '../../models/challenges/challenge.dart';
import '../../models/challenges/challenge_draft.dart';
import '../../models/challenges/challenge_draft_validator.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Crea un reto con sus tareas opcionales tras validarlo con las reglas del servidor.
abstract interface class CreateChallengeUseCaseContract {
  Future<AppResult<Challenge>> call(ChallengeDraft draft);
}

class CreateChallengeUseCase implements CreateChallengeUseCaseContract {
  const CreateChallengeUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Challenge>> call(ChallengeDraft draft) async {
    final issue = ChallengeDraftValidator.validate(draft);
    if (issue != null) return Failure(issue.asError);
    return _repository.create(draft);
  }
}
