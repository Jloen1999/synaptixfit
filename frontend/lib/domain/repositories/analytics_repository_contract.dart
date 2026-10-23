import '../enums/analytics_enums.dart';
import '../enums/analytics_period.dart';
import '../models/progress/analytics_insight.dart';
import '../models/progress/load_correlation.dart';
import '../models/progress/rpe_trend.dart';
import '../models/progress/study_week.dart';
import '../models/progress/training_volume.dart';
import '../models/progress/weekly_analytics.dart';
import '../models/result/app_result.dart';

/// Analítica de entrenamiento (`/api/v1/analytics`).
abstract interface class AnalyticsRepositoryContract {
  Future<AppResult<WeeklyAnalytics>> getWeekly(AnalyticsPeriod period);

  Future<AppResult<TrainingVolume>> getVolume(AnalyticsPeriod period);

  Future<AppResult<RpeTrend>> getRpeTrend(AnalyticsPeriod period);

  Future<AppResult<LoadCorrelation>> getCorrelation(CorrelationMetric metric);

  Future<AppResult<List<AnalyticsInsight>>> getInsights(AnalyticsPeriod period);

  /// «Tu estudio» de la semana en curso.
  Future<AppResult<StudyWeek>> getStudyWeek();
}
