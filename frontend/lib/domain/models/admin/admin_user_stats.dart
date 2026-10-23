import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/admin/admin_timeline_type.dart';

part 'admin_user_stats.freezed.dart';

/// Cifras acumuladas de actividad de un usuario.
@freezed
abstract class AdminUserStats with _$AdminUserStats {
  const factory AdminUserStats({
    required int trainingSessions,
    required int trainingMinutes,
    required int caloriesBurned,
    double? averageRpe,
    required int routines,
    required int activeRoutines,
    required int challenges,
    required int completedChallenges,
    required int badges,
    required int subjects,
    required int notes,
    required int files,
    required int completedStudyBlocks,
    required int studyMinutes,
    required int focusSessions,
    required int focusMinutes,
    required int completedDeadlines,
    required int pendingDeadlines,
    required int posts,
    required int comments,
    required int friends,
    required int academicAdherencePercent,
    required int adherenceWeeks,
    DateTime? lastActivityAt,
  }) = _AdminUserStats;
}

/// Actividad de una semana (lunes a domingo) de un usuario.
@freezed
abstract class AdminWeeklyActivity with _$AdminWeeklyActivity {
  const factory AdminWeeklyActivity({
    required DateTime weekStart,
    required int trainingSessions,
    required int trainingMinutes,
    required int calories,
    double? averageRpe,
    required int studyMinutes,
    required int focusMinutes,
  }) = _AdminWeeklyActivity;
}

/// Evento de la línea de tiempo de un usuario.
@freezed
abstract class AdminTimelineEntry with _$AdminTimelineEntry {
  const factory AdminTimelineEntry({
    required DateTime occurredAt,
    required AdminTimelineType type,
    String? referenceId,
    String? title,
    int? value,
  }) = _AdminTimelineEntry;
}
