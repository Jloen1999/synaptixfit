import '../../models/progress/streak.dart';
import '../../models/result/app_result.dart';
import '../../repositories/badge_repository_contract.dart';

/// «Reanudar» la racha en pausa (ADR 0042).
abstract interface class ResumeStreakUseCaseContract {
  Future<AppResult<Streak>> call();
}

class ResumeStreakUseCase implements ResumeStreakUseCaseContract {
  const ResumeStreakUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<Streak>> call() => _repository.resumeStreak();
}
