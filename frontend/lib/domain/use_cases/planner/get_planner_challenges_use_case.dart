import '../../models/planner/planner_options.dart';
import '../../models/result/app_result.dart';
import '../../repositories/planner_repository_contract.dart';

/// Retos activos del usuario para vincular.
abstract interface class GetPlannerChallengesUseCaseContract {
  Future<AppResult<List<ChallengeOption>>> call();
}

class GetPlannerChallengesUseCase
    implements GetPlannerChallengesUseCaseContract {
  const GetPlannerChallengesUseCase(this._repository);

  final PlannerRepositoryContract _repository;

  @override
  Future<AppResult<List<ChallengeOption>>> call() =>
      _repository.getChallenges();
}
