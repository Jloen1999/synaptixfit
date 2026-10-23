import '../../models/admin/admin_user.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Cuenta y perfiles de un usuario.
abstract interface class GetAdminUserDetailUseCaseContract {
  Future<AppResult<AdminUserDetail>> call(String userId);
}

class GetAdminUserDetailUseCase implements GetAdminUserDetailUseCaseContract {
  const GetAdminUserDetailUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminUserDetail>> call(String userId) =>
      _repository.getUserDetail(userId);
}
