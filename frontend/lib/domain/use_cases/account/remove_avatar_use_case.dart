import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/account_repository_contract.dart';

/// Quita la foto de perfil y devuelve la cuenta (vuelven las iniciales).
abstract interface class RemoveAvatarUseCaseContract {
  Future<AppResult<Account>> call();
}

class RemoveAvatarUseCase implements RemoveAvatarUseCaseContract {
  const RemoveAvatarUseCase(this._repository);

  final AccountRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call() => _repository.removeAvatar();
}
