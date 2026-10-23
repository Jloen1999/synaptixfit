import '../../models/admin/admin_user_stats.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Actividad semanal de un usuario en las últimas [weeks] semanas.
abstract interface class GetAdminUserActivityUseCaseContract {
  Future<AppResult<List<AdminWeeklyActivity>>> call(
    String userId, {
    required int weeks,
  });
}

class GetAdminUserActivityUseCase
    implements GetAdminUserActivityUseCaseContract {
  const GetAdminUserActivityUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<List<AdminWeeklyActivity>>> call(
    String userId, {
    required int weeks,
  }) => _repository.getUserActivity(userId, weeks: weeks);
}
