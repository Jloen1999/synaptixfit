import '../../enums/user_role.dart';
import '../../models/admin/admin_user.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Cambia el rol de un usuario.
abstract interface class ChangeAdminUserRoleUseCaseContract {
  Future<AppResult<AdminUserAccount>> call(String userId, UserRole role);
}

class ChangeAdminUserRoleUseCase implements ChangeAdminUserRoleUseCaseContract {
  const ChangeAdminUserRoleUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminUserAccount>> call(String userId, UserRole role) =>
      _repository.changeUserRole(userId, role);
}
