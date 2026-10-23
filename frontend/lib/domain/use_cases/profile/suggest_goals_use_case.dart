import '../../enums/profile/activity_level.dart';
import '../../enums/profile/sex.dart';
import '../../models/profile/wellness_history.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Sugiere objetivos de entrenamiento (IA con reglas de respaldo).
abstract interface class SuggestGoalsUseCaseContract {
  Future<AppResult<GoalSuggestions>> call({
    int? age,
    Sex? sex,
    ActivityLevel? activityLevel,
  });
}

class SuggestGoalsUseCase implements SuggestGoalsUseCaseContract {
  const SuggestGoalsUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<GoalSuggestions>> call({
    int? age,
    Sex? sex,
    ActivityLevel? activityLevel,
  }) => _repository.suggestGoals(
    age: age,
    sex: sex,
    activityLevel: activityLevel,
  );
}
