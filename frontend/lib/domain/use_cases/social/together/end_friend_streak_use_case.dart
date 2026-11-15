import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Termina una racha con un amigo (o retira la propuesta).
abstract interface class EndFriendStreakUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [EndFriendStreakUseCaseContract] con [TogetherRepositoryContract].
class EndFriendStreakUseCase implements EndFriendStreakUseCaseContract {
  const EndFriendStreakUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.endStreak(id);
}
