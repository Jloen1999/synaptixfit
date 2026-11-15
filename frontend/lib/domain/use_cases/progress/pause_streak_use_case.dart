import '../../models/progress/streak.dart';
import '../../models/result/app_result.dart';
import '../../repositories/badge_repository_contract.dart';

/// «Pausar racha» en un toque, sin motivo (ADR 0042). Cuánto dura y el tope
/// los decide el servidor.
abstract interface class PauseStreakUseCaseContract {
  Future<AppResult<Streak>> call();
}

class PauseStreakUseCase implements PauseStreakUseCaseContract {
  const PauseStreakUseCase(this._repository);

  final BadgeRepositoryContract _repository;

  @override
  Future<AppResult<Streak>> call() => _repository.pauseStreak();
}
