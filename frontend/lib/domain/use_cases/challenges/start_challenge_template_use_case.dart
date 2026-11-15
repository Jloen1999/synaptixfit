import '../../models/challenges/challenge.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// «Empezar este reto»: crea un reto propio y privado desde una plantilla; el
/// servidor lo cuenta solo (ADR 0043).
abstract interface class StartChallengeTemplateUseCaseContract {
  Future<AppResult<Challenge>> call(String templateId);
}

class StartChallengeTemplateUseCase
    implements StartChallengeTemplateUseCaseContract {
  const StartChallengeTemplateUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<Challenge>> call(String templateId) =>
      _repository.startTemplate(templateId);
}
