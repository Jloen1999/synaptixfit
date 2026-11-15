import '../../../models/challenges/challenge_template.dart';
import '../../../models/result/app_result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Plantillas que valen para un reto con amigos (nunca las de bienestar).
abstract interface class GetFriendChallengeTemplatesUseCaseContract {
  Future<AppResult<List<ChallengeTemplate>>> call();
}

/// Implementa [GetFriendChallengeTemplatesUseCaseContract] con [TogetherRepositoryContract].
class GetFriendChallengeTemplatesUseCase
    implements GetFriendChallengeTemplatesUseCaseContract {
  const GetFriendChallengeTemplatesUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<List<ChallengeTemplate>>> call() =>
      _repository.challengeTemplates();
}
