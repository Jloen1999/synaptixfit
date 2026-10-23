import '../../models/admin/platform_metrics.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Indicadores globales de la plataforma.
abstract interface class GetPlatformMetricsUseCaseContract {
  Future<AppResult<PlatformMetrics>> call();
}

class GetPlatformMetricsUseCase implements GetPlatformMetricsUseCaseContract {
  const GetPlatformMetricsUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<PlatformMetrics>> call() => _repository.getMetrics();
}
