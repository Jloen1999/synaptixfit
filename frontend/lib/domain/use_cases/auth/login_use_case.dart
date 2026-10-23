import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/auth_repository_contract.dart';

abstract interface class LoginUseCaseContract {
  Future<AppResult<Account>> call({
    required String email,
    required String password,
  });
}

class LoginUseCase implements LoginUseCaseContract {
  const LoginUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email.trim(), password: password);
}
