import '../../models/admin/admin_user_stats.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Cifras de actividad de un usuario.
abstract interface class GetAdminUserStatsUseCaseContract {
  Future<AppResult<AdminUserStats>> call(String userId);
}

class GetAdminUserStatsUseCase implements GetAdminUserStatsUseCaseContract {
  const GetAdminUserStatsUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminUserStats>> call(String userId) =>
      _repository.getUserStats(userId);
}
