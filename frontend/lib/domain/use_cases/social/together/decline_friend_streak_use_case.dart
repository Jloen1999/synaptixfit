import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Dice que no a una racha propuesta.
abstract interface class DeclineFriendStreakUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [DeclineFriendStreakUseCaseContract] con [TogetherRepositoryContract].
class DeclineFriendStreakUseCase implements DeclineFriendStreakUseCaseContract {
  const DeclineFriendStreakUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.declineStreak(id);
}
