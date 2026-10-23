import '../../domain/enums/analytics_enums.dart';
import '../../domain/enums/analytics_period.dart';
import '../../domain/models/progress/analytics_insight.dart';
import '../../domain/models/progress/load_correlation.dart';
import '../../domain/models/progress/rpe_trend.dart';
import '../../domain/models/progress/study_week.dart';
import '../../domain/models/progress/training_volume.dart';
import '../../domain/models/progress/weekly_analytics.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/analytics_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/progress/analytics_remote_data_source.dart';

class AnalyticsRepository implements AnalyticsRepositoryContract {
  AnalyticsRepository(this._remote);

  final AnalyticsRemoteDataSource _remote;

  @override
  Future<AppResult<StudyWeek>> getStudyWeek() => RepositoryErrorHandler.guard(
    () async => (await _remote.studyWeek()).toDomain(),
  );

  @override
  Future<AppResult<WeeklyAnalytics>> getWeekly(AnalyticsPeriod period) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.weekly(period.apiValue)).toDomain(),
      );

  @override
  Future<AppResult<TrainingVolume>> getVolume(AnalyticsPeriod period) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.volume(period.apiValue)).toDomain(),
      );

  @override
  Future<AppResult<RpeTrend>> getRpeTrend(AnalyticsPeriod period) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.rpeTrend(period.apiValue)).toDomain(),
      );

  @override
  Future<AppResult<LoadCorrelation>> getCorrelation(CorrelationMetric metric) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.correlation(metric.apiValue)).toDomain(),
      );

  @override
  Future<AppResult<List<AnalyticsInsight>>> getInsights(
    AnalyticsPeriod period,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.insights(
      period.apiValue,
    )).map((i) => i.toDomain()).toList(),
  );
}
