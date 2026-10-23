import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/account_repository_contract.dart';

abstract interface class GetAccountUseCaseContract {
  Future<AppResult<Account>> call();
}

class GetAccountUseCase implements GetAccountUseCaseContract {
  const GetAccountUseCase(this._repository);

  final AccountRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call() => _repository.getAccount();
}
