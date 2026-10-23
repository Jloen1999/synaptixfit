import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/account_privacy_repository_contract.dart';

/// Elimina la cuenta del usuario.
abstract interface class DeleteMyAccountUseCaseContract {
  Future<AppResult<Unit>> call({String? password, bool confirm = false});
}

class DeleteMyAccountUseCase implements DeleteMyAccountUseCaseContract {
  const DeleteMyAccountUseCase(this._repository);

  final AccountPrivacyRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({String? password, bool confirm = false}) =>
      _repository.deleteMyAccount(password: password, confirm: confirm);
}
