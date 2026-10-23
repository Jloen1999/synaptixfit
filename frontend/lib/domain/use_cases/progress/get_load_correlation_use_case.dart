import '../../enums/analytics_enums.dart';
import '../../models/progress/load_correlation.dart';
import '../../models/result/app_result.dart';
import '../../repositories/analytics_repository_contract.dart';

/// Correlación estudio ↔ entrenamiento para la métrica elegida.
abstract interface class GetLoadCorrelationUseCaseContract {
  Future<AppResult<LoadCorrelation>> call(CorrelationMetric metric);
}

class GetLoadCorrelationUseCase implements GetLoadCorrelationUseCaseContract {
  const GetLoadCorrelationUseCase(this._repository);

  final AnalyticsRepositoryContract _repository;

  @override
  Future<AppResult<LoadCorrelation>> call(CorrelationMetric metric) =>
      _repository.getCorrelation(metric);
}
