import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/account_repository_contract.dart';

abstract interface class ChangePasswordUseCaseContract {
  Future<AppResult<Unit>> call({
    String? currentPassword,
    required String newPassword,
  });
}

class ChangePasswordUseCase implements ChangePasswordUseCaseContract {
  const ChangePasswordUseCase(this._repository);

  final AccountRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({
    String? currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
