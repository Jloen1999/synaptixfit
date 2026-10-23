import '../../models/admin/admin_user.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Activa o retira el shadowban de un usuario.
abstract interface class SetAdminUserShadowbanUseCaseContract {
  Future<AppResult<AdminUserAccount>> call(
    String userId, {
    required bool shadowbanned,
  });
}

class SetAdminUserShadowbanUseCase
    implements SetAdminUserShadowbanUseCaseContract {
  const SetAdminUserShadowbanUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminUserAccount>> call(
    String userId, {
    required bool shadowbanned,
  }) => _repository.setUserShadowban(userId, shadowbanned: shadowbanned);
}
