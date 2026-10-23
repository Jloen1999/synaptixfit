import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_metrics.freezed.dart';

/// Indicadores globales de la plataforma (pestaña KPIs).
@freezed
abstract class PlatformMetrics with _$PlatformMetrics {
  const factory PlatformMetrics({
    required int totalUsers,
    required int activeUsersToday,
    required int trainingSessionsToday,
    required int activeRoutines,
    required int activeChallenges,
    required int pendingReportedContent,
    required int newUsersToday,
    required int shadowbannedUsers,
  }) = _PlatformMetrics;
}

/// Actividad agregada de un día para la gráfica de tendencia.
@freezed
abstract class DailyActivity with _$DailyActivity {
  const factory DailyActivity({
    required DateTime date,
    required int signups,
    required int activeUsers,
    required int trainingSessions,
  }) = _DailyActivity;
}
