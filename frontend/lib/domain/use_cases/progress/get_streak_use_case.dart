import '../../models/progress/streak.dart';
import '../../models/result/app_result.dart';
import '../../repositories/badge_repository_contract.dart';

/// Racha diaria de actividad (la calcula el servidor).
abstract interface class GetStreakUseCaseContract {
  Future<AppResult<Streak>> call();
}

class GetStreakUseCase implements GetStreakUseCaseContract {
  const GetStreakUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<Streak>> call() => _repository.getStreak();
}
