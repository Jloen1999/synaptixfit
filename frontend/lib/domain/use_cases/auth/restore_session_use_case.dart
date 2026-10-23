import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/auth_repository_contract.dart';

abstract interface class RestoreSessionUseCaseContract {
  Future<AppResult<Account?>> call();
}

class RestoreSessionUseCase implements RestoreSessionUseCaseContract {
  const RestoreSessionUseCase(this._repository);

  final AuthRepositoryContract _repository;

  @override
  Future<AppResult<Account?>> call() => _repository.restoreSession();
}
