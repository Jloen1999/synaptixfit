import '../../models/challenges/challenge_template.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenges_repository_contract.dart';

/// Plantillas de retos productivos para el modo de uso de la persona (ADR 0043).
abstract interface class ListChallengeTemplatesUseCaseContract {
  Future<AppResult<List<ChallengeTemplate>>> call();
}

class ListChallengeTemplatesUseCase
    implements ListChallengeTemplatesUseCaseContract {
  const ListChallengeTemplatesUseCase(this._repository);

  final ChallengesRepositoryContract _repository;

  @override
  Future<AppResult<List<ChallengeTemplate>>> call() => _repository.templates();
}
