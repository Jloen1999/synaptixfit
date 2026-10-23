import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/admin/admin_timeline_type.dart';
import '../../../../domain/models/admin/admin_user_stats.dart';
import 'admin_json.dart';

part 'admin_user_stats_dto.freezed.dart';
part 'admin_user_stats_dto.g.dart';

@freezed
abstract class AdminUserStatsDto with _$AdminUserStatsDto {
  const factory AdminUserStatsDto({
    @Default(0) int trainingSessions,
    @Default(0) int trainingMinutes,
    @Default(0) int caloriesBurned,
    double? averageRpe,
    @Default(0) int routines,
    @Default(0) int activeRoutines,
    @Default(0) int challenges,
    @Default(0) int completedChallenges,
    @Default(0) int badges,
    @Default(0) int subjects,
    @Default(0) int notes,
    @Default(0) int files,
    @Default(0) int completedStudyBlocks,
    @Default(0) int studyMinutes,
    @Default(0) int focusSessions,
    @Default(0) int focusMinutes,
    @Default(0) int completedDeadlines,
    @Default(0) int pendingDeadlines,
    @Default(0) int posts,
    @Default(0) int comments,
    @Default(0) int friends,
    @Default(0) int academicAdherencePercent,
    @Default(0) int adherenceWeeks,
    String? lastActivityAt,
  }) = _AdminUserStatsDto;

  const AdminUserStatsDto._();

  factory AdminUserStatsDto.fromJson(Map<String, dynamic> json) =>
      _$AdminUserStatsDtoFromJson(json);

  AdminUserStats toDomain() => AdminUserStats(
    trainingSessions: trainingSessions,
    trainingMinutes: trainingMinutes,
    caloriesBurned: caloriesBurned,
    averageRpe: averageRpe,
    routines: routines,
    activeRoutines: activeRoutines,
    challenges: challenges,
    completedChallenges: completedChallenges,
    badges: badges,
    subjects: subjects,
    notes: notes,
    files: files,
    completedStudyBlocks: completedStudyBlocks,
    studyMinutes: studyMinutes,
    focusSessions: focusSessions,
    focusMinutes: focusMinutes,
    completedDeadlines: completedDeadlines,
    pendingDeadlines: pendingDeadlines,
    posts: posts,
    comments: comments,
    friends: friends,
    academicAdherencePercent: academicAdherencePercent,
    adherenceWeeks: adherenceWeeks,
    lastActivityAt: AdminJson.instant(lastActivityAt),
  );
}

@freezed
abstract class AdminWeeklyActivityDto with _$AdminWeeklyActivityDto {
  const factory AdminWeeklyActivityDto({
    required String weekStart,
    @Default(0) int trainingSessions,
    @Default(0) int trainingMinutes,
    @Default(0) int calories,
    double? averageRpe,
    @Default(0) int studyMinutes,
    @Default(0) int focusMinutes,
  }) = _AdminWeeklyActivityDto;

  const AdminWeeklyActivityDto._();

  factory AdminWeeklyActivityDto.fromJson(Map<String, dynamic> json) =>
      _$AdminWeeklyActivityDtoFromJson(json);

  AdminWeeklyActivity toDomain() => AdminWeeklyActivity(
    weekStart: AdminJson.date(weekStart)!,
    trainingSessions: trainingSessions,
    trainingMinutes: trainingMinutes,
    calories: calories,
    averageRpe: averageRpe,
    studyMinutes: studyMinutes,
    focusMinutes: focusMinutes,
  );
}

@freezed
abstract class AdminTimelineEntryDto with _$AdminTimelineEntryDto {
  const factory AdminTimelineEntryDto({
    required String occurredAt,
    String? type,
    String? referenceId,
    String? title,
    int? value,
  }) = _AdminTimelineEntryDto;

  const AdminTimelineEntryDto._();

  factory AdminTimelineEntryDto.fromJson(Map<String, dynamic> json) =>
      _$AdminTimelineEntryDtoFromJson(json);

  AdminTimelineEntry toDomain() => AdminTimelineEntry(
    occurredAt: AdminJson.instant(occurredAt)!,
    type: AdminTimelineType.fromApi(type),
    referenceId: referenceId,
    title: title,
    value: value,
  );
}
