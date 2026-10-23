import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/admin/lockdown_status.dart';
import '../../../../domain/models/admin/platform_metrics.dart';
import 'admin_json.dart';

part 'platform_metrics_dto.freezed.dart';
part 'platform_metrics_dto.g.dart';

@freezed
abstract class PlatformMetricsDto with _$PlatformMetricsDto {
  const factory PlatformMetricsDto({
    @Default(0) int totalUsers,
    @Default(0) int activeUsersToday,
    @Default(0) int trainingSessionsToday,
    @Default(0) int activeRoutines,
    @Default(0) int activeChallenges,
    @Default(0) int pendingReportedContent,
    @Default(0) int newUsersToday,
    @Default(0) int shadowbannedUsers,
  }) = _PlatformMetricsDto;

  const PlatformMetricsDto._();

  factory PlatformMetricsDto.fromJson(Map<String, dynamic> json) =>
      _$PlatformMetricsDtoFromJson(json);

  PlatformMetrics toDomain() => PlatformMetrics(
    totalUsers: totalUsers,
    activeUsersToday: activeUsersToday,
    trainingSessionsToday: trainingSessionsToday,
    activeRoutines: activeRoutines,
    activeChallenges: activeChallenges,
    pendingReportedContent: pendingReportedContent,
    newUsersToday: newUsersToday,
    shadowbannedUsers: shadowbannedUsers,
  );
}

@freezed
abstract class DailyActivityDto with _$DailyActivityDto {
  const factory DailyActivityDto({
    required String date,
    @Default(0) int signups,
    @Default(0) int activeUsers,
    @Default(0) int trainingSessions,
  }) = _DailyActivityDto;

  const DailyActivityDto._();

  factory DailyActivityDto.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityDtoFromJson(json);

  DailyActivity toDomain() => DailyActivity(
    date: AdminJson.date(date)!,
    signups: signups,
    activeUsers: activeUsers,
    trainingSessions: trainingSessions,
  );
}

@freezed
abstract class LockdownDto with _$LockdownDto {
  const factory LockdownDto({
    @Default(false) bool active,
    String? startedAt,
    String? startedBy,
    String? updatedAt,
  }) = _LockdownDto;

  const LockdownDto._();

  factory LockdownDto.fromJson(Map<String, dynamic> json) =>
      _$LockdownDtoFromJson(json);

  LockdownStatus toDomain() => LockdownStatus(
    active: active,
    startedAt: AdminJson.instant(startedAt),
    startedBy: startedBy,
    updatedAt: AdminJson.instant(updatedAt),
  );
}
