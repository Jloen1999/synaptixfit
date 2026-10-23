import '../../models/admin/platform_metrics.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Altas, activos y sesiones por día de los últimos [days] días.
abstract interface class GetActivityTrendUseCaseContract {
  Future<AppResult<List<DailyActivity>>> call({required int days});
}

class GetActivityTrendUseCase implements GetActivityTrendUseCaseContract {
  const GetActivityTrendUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<List<DailyActivity>>> call({required int days}) =>
      _repository.getActivityTrend(days: days);
}
