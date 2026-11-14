import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/analytics_enums.dart';
import '../../../../domain/enums/analytics_period.dart';
import '../../../../domain/models/progress/analytics_insight.dart';
import '../../../../domain/models/progress/load_correlation.dart';
import '../../../../domain/models/progress/rpe_trend.dart';
import '../../../../domain/models/progress/training_volume.dart';
import '../../../../domain/models/progress/weekly_analytics.dart';
import '../../../../domain/models/progress/study_week.dart';

part 'analytics_dto.freezed.dart';
part 'analytics_dto.g.dart';

/// Las semanas llegan como fecha (`2026-10-12`): se interpretan en hora local.
DateTime _week(String value) {
  final d = DateTime.parse(value);
  return DateTime(d.year, d.month, d.day);
}

/// `WeeklyAnalyticsResponse`.
@freezed
abstract class WeeklyAnalyticsDto with _$WeeklyAnalyticsDto {
  const factory WeeklyAnalyticsDto({
    String? period,

    /// Semana en curso según el servidor (lunes, `2026-10-12`).
    String? toWeek,
    @Default(<WeekMetricDto>[]) List<WeekMetricDto> weeks,
    @Default(0) int totalSessions,
    @Default(0) int totalMinutes,
    @Default(0) int totalCalories,
    double? averageRpe,
  }) = _WeeklyAnalyticsDto;

  const WeeklyAnalyticsDto._();

  factory WeeklyAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyAnalyticsDtoFromJson(json);

  WeeklyAnalytics toDomain() => WeeklyAnalytics(
    period: AnalyticsPeriod.fromApi(period),
    currentWeekStart: toWeek == null ? null : _week(toWeek!),
    weeks: weeks.map((w) => w.toDomain()).toList(),
    totalSessions: totalSessions,
    totalMinutes: totalMinutes,
    totalCalories: totalCalories,
    averageRpe: averageRpe,
  );
}

@freezed
abstract class WeekMetricDto with _$WeekMetricDto {
  const factory WeekMetricDto({
    required String weekStart,
    @Default(0) int sessions,
    double? averageRpe,
    @Default(0) int totalMinutes,
    @Default(0) int totalCalories,
  }) = _WeekMetricDto;

  const WeekMetricDto._();

  factory WeekMetricDto.fromJson(Map<String, dynamic> json) =>
      _$WeekMetricDtoFromJson(json);

  WeekMetric toDomain() => WeekMetric(
    weekStart: _week(weekStart),
    sessions: sessions,
    averageRpe: averageRpe,
    totalMinutes: totalMinutes,
    totalCalories: totalCalories,
  );
}

/// `TrainingVolumeResponse`.
@freezed
abstract class TrainingVolumeDto with _$TrainingVolumeDto {
  const factory TrainingVolumeDto({
    @Default(<VolumePointDto>[]) List<VolumePointDto> points,
    @Default(0) double averageMinutesPerWeek,
    @Default(0) double averageCaloriesPerWeek,
    @Default(0) double averageSessionsPerWeek,
  }) = _TrainingVolumeDto;

  const TrainingVolumeDto._();

  factory TrainingVolumeDto.fromJson(Map<String, dynamic> json) =>
      _$TrainingVolumeDtoFromJson(json);

  TrainingVolume toDomain() => TrainingVolume(
    points: points.map((p) => p.toDomain()).toList(),
    averageMinutesPerWeek: averageMinutesPerWeek,
    averageCaloriesPerWeek: averageCaloriesPerWeek,
    averageSessionsPerWeek: averageSessionsPerWeek,
  );
}

@freezed
abstract class VolumePointDto with _$VolumePointDto {
  const factory VolumePointDto({
    required String weekStart,
    @Default(0) int sessions,
    @Default(0) int minutes,
    @Default(0) int calories,
  }) = _VolumePointDto;

  const VolumePointDto._();

  factory VolumePointDto.fromJson(Map<String, dynamic> json) =>
      _$VolumePointDtoFromJson(json);

  VolumePoint toDomain() => VolumePoint(
    weekStart: _week(weekStart),
    sessions: sessions,
    minutes: minutes,
    calories: calories,
  );
}

/// `RpeTrendResponse`.
@freezed
abstract class RpeTrendDto with _$RpeTrendDto {
  const factory RpeTrendDto({
    @Default(<RpePointDto>[]) List<RpePointDto> points,
    double? slopePerWeek,
    String? direction,
  }) = _RpeTrendDto;

  const RpeTrendDto._();

  factory RpeTrendDto.fromJson(Map<String, dynamic> json) =>
      _$RpeTrendDtoFromJson(json);

  RpeTrend toDomain() => RpeTrend(
    points: points.map((p) => p.toDomain()).toList(),
    slopePerWeek: slopePerWeek,
    direction: TrendDirection.fromApi(direction),
  );
}

@freezed
abstract class RpePointDto with _$RpePointDto {
  const factory RpePointDto({
    required String weekStart,
    @Default(0) double averageRpe,
  }) = _RpePointDto;

  const RpePointDto._();

  factory RpePointDto.fromJson(Map<String, dynamic> json) =>
      _$RpePointDtoFromJson(json);

  RpePoint toDomain() =>
      RpePoint(weekStart: _week(weekStart), averageRpe: averageRpe);
}

/// `CorrelationResponse`.
@freezed
abstract class CorrelationDto with _$CorrelationDto {
  const factory CorrelationDto({
    String? metric,
    double? coefficient,
    @Default(0) int sampleSize,
    @Default(0) int minimumSampleSize,
    @Default(false) bool sufficientData,
    String? strength,
    String? direction,
    @Default(<CorrelationPointDto>[]) List<CorrelationPointDto> points,
  }) = _CorrelationDto;

  const CorrelationDto._();

  factory CorrelationDto.fromJson(Map<String, dynamic> json) =>
      _$CorrelationDtoFromJson(json);

  LoadCorrelation toDomain() {
    // Sin coeficiente no hay correlación que mostrar aunque la API diga lo contrario.
    final sufficient = sufficientData && coefficient != null;
    return LoadCorrelation(
      metric: CorrelationMetric.fromApi(metric),
      coefficient: sufficient ? coefficient : null,
      sampleSize: sampleSize,
      minimumSampleSize: minimumSampleSize,
      sufficientData: sufficient,
      strength: sufficient ? CorrelationStrength.fromApi(strength) : null,
      direction: sufficient ? CorrelationDirection.fromApi(direction) : null,
      points: points.map((p) => p.toDomain()).toList(),
    );
  }
}

@freezed
abstract class CorrelationPointDto with _$CorrelationPointDto {
  const factory CorrelationPointDto({
    required String weekStart,
    @Default(0) double studyHours,
    @Default(0) double trainingValue,
  }) = _CorrelationPointDto;

  const CorrelationPointDto._();

  factory CorrelationPointDto.fromJson(Map<String, dynamic> json) =>
      _$CorrelationPointDtoFromJson(json);

  CorrelationPoint toDomain() => CorrelationPoint(
    weekStart: _week(weekStart),
    studyHours: studyHours,
    trainingValue: trainingValue,
  );
}

/// `InsightResponse`.
@freezed
abstract class InsightDto with _$InsightDto {
  const factory InsightDto({
    String? type,
    String? severity,
    @Default('') String variant,
    @Default(<String, num>{}) Map<String, num> params,
  }) = _InsightDto;

  const InsightDto._();

  factory InsightDto.fromJson(Map<String, dynamic> json) =>
      _$InsightDtoFromJson(json);

  AnalyticsInsight toDomain() => AnalyticsInsight(
    type: InsightType.fromApi(type),
    severity: InsightSeverity.fromApi(severity),
    variant: variant,
    params: params,
  );
}

/// Respuesta de `GET /analytics/study-week`.
@freezed
abstract class StudyWeekDto with _$StudyWeekDto {
  const factory StudyWeekDto({
    required String weekStart,
    @Default(0) int focusMinutes,
    @Default(0) int focusSessions,
    @Default(0) int studyBlocksPlanned,
    @Default(0) int studyBlocksCompleted,
    int? planAdherence,
    @Default(0) int reviewsCompleted,
    @Default(0) int testsCompleted,
    int? averageTestScore,
    @Default(0) int reviewsDue,
    @Default(0) int studyHours,
    @Default(0) int weeklyGoalHours,
    @Default(true) bool empty,
  }) = _StudyWeekDto;

  const StudyWeekDto._();

  factory StudyWeekDto.fromJson(Map<String, dynamic> json) =>
      _$StudyWeekDtoFromJson(json);

  StudyWeek toDomain() => StudyWeek(
    weekStart: DateTime.parse(weekStart),
    focusMinutes: focusMinutes,
    focusSessions: focusSessions,
    studyBlocksPlanned: studyBlocksPlanned,
    studyBlocksCompleted: studyBlocksCompleted,
    planAdherence: planAdherence,
    reviewsCompleted: reviewsCompleted,
    testsCompleted: testsCompleted,
    averageTestScore: averageTestScore,
    reviewsDue: reviewsDue,
    studyHours: studyHours,
    weeklyGoalHours: weeklyGoalHours,
    empty: empty,
  );
}
