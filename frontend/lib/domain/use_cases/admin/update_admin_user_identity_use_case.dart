import '../../models/admin/admin_user.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Cambia el nombre y/o el email de un usuario (nulo = sin cambios).
abstract interface class UpdateAdminUserIdentityUseCaseContract {
  Future<AppResult<AdminUserAccount>> call(
    String userId, {
    String? fullName,
    String? email,
  });
}

class UpdateAdminUserIdentityUseCase
    implements UpdateAdminUserIdentityUseCaseContract {
  const UpdateAdminUserIdentityUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminUserAccount>> call(
    String userId, {
    String? fullName,
    String? email,
  }) =>
      _repository.updateUserIdentity(userId, fullName: fullName, email: email);
}
