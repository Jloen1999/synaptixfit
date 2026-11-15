import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// «Recordárselo»: aviso suave al amigo, como mucho uno al día.
abstract interface class NudgeFriendStreakUseCaseContract {
  Future<AppResult<FriendStreak>> call(String id);
}

/// Implementa [NudgeFriendStreakUseCaseContract] con [TogetherRepositoryContract].
class NudgeFriendStreakUseCase implements NudgeFriendStreakUseCaseContract {
  const NudgeFriendStreakUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<FriendStreak>> call(String id) =>
      _repository.nudgeStreak(id);
}
