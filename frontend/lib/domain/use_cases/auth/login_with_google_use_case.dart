import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/auth_repository_contract.dart';

abstract interface class LoginWithGoogleUseCaseContract {
  Future<AppResult<Account>> call();
}

class LoginWithGoogleUseCase implements LoginWithGoogleUseCaseContract {
  const LoginWithGoogleUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call() => _repository.loginWithGoogle();
}
