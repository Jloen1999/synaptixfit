import 'dart:async';

import '../../enums/analytics_enums.dart';
import '../../enums/analytics_period.dart';
import '../../models/progress/analytics_report.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/analytics_repository_contract.dart';

/// Carga en paralelo toda la analítica de un periodo.
abstract interface class GetAnalyticsReportUseCaseContract {
  Future<AppResult<AnalyticsReport>> call({
    required AnalyticsPeriod period,
    required CorrelationMetric metric,
  });
}

class GetAnalyticsReportUseCase implements GetAnalyticsReportUseCaseContract {
  const GetAnalyticsReportUseCase(this._repository);

  final AnalyticsRepositoryContract _repository;

  @override
  Future<AppResult<AnalyticsReport>> call({
    required AnalyticsPeriod period,
    required CorrelationMetric metric,
  }) async {
    final (weekly, volume, rpe, correlation, insights) = await (
      _repository.getWeekly(period),
      _repository.getVolume(period),
      _repository.getRpeTrend(period),
      _repository.getCorrelation(metric),
      _repository.getInsights(period),
    ).wait;

    return switch ((weekly, volume, rpe, correlation, insights)) {
      (
        Success(value: final w),
        Success(value: final v),
        Success(value: final r),
        Success(value: final c),
        Success(value: final i),
      ) =>
        Success(
          AnalyticsReport(
            weekly: w,
            volume: v,
            rpeTrend: r,
            correlation: c,
            insights: i,
          ),
        ),
      _ => Failure(
        [
          weekly.errorOrNull,
          volume.errorOrNull,
          rpe.errorOrNull,
          correlation.errorOrNull,
          insights.errorOrNull,
        ].nonNulls.first,
      ),
    };
  }
}
