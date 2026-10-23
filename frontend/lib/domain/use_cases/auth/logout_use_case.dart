import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/auth_repository_contract.dart';

abstract interface class LogoutUseCaseContract {
  Future<AppResult<Unit>> call();
}

class LogoutUseCase implements LogoutUseCaseContract {
  const LogoutUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.logout();
}
