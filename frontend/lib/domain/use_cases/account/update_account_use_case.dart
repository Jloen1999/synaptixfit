import '../../enums/usage_focus.dart';
import '../../enums/visibility.dart';
import '../../models/account/account.dart';
import '../../models/result/app_result.dart';
import '../../repositories/account_repository_contract.dart';

abstract interface class UpdateAccountUseCaseContract {
  Future<AppResult<Account>> call({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
  });
}

class UpdateAccountUseCase implements UpdateAccountUseCaseContract {
  const UpdateAccountUseCase(this._repository);

  final AccountRepositoryContract _repository;

  @override
  Future<AppResult<Account>> call({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
  }) => _repository.updateAccount(
    fullName: fullName,
    avatarUrl: avatarUrl,
    privacy: privacy,
    usageFocus: usageFocus,
  );
}
