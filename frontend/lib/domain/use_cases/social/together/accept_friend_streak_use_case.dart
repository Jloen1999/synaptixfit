import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Acepta una racha propuesta: cuenta desde hoy.
abstract interface class AcceptFriendStreakUseCaseContract {
  Future<AppResult<FriendStreak>> call(String id);
}

/// Implementa [AcceptFriendStreakUseCaseContract] con [TogetherRepositoryContract].
class AcceptFriendStreakUseCase implements AcceptFriendStreakUseCaseContract {
  const AcceptFriendStreakUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<FriendStreak>> call(String id) =>
      _repository.acceptStreak(id);
}
