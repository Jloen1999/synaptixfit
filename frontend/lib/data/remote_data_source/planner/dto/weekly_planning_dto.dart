import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/weekly_planning.dart';
import 'planner_json.dart';

part 'weekly_planning_dto.freezed.dart';
part 'weekly_planning_dto.g.dart';

@freezed
abstract class StudyPlanDto with _$StudyPlanDto {
  const factory StudyPlanDto({required String id, @Default('') String name}) =
      _StudyPlanDto;

  factory StudyPlanDto.fromJson(Map<String, dynamic> json) =>
      _$StudyPlanDtoFromJson(json);
}

@freezed
abstract class SavePlanResponseDto with _$SavePlanResponseDto {
  const factory SavePlanResponseDto({
    required StudyPlanDto plan,
    @Default(0) int blockCount,
    @Default(0) int deadlineCount,
    @Default(0) int xpAwarded,
  }) = _SavePlanResponseDto;

  const SavePlanResponseDto._();

  factory SavePlanResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SavePlanResponseDtoFromJson(json);

  SavedPlan toDomain() => SavedPlan(
    planId: plan.id,
    name: plan.name,
    blockCount: blockCount,
    deadlineCount: deadlineCount,
    xpAwarded: xpAwarded,
  );
}

@freezed
abstract class WeeklyLoadDto with _$WeeklyLoadDto {
  const factory WeeklyLoadDto({
    required String weekStart,
    @Default(0) int plannedHours,
    @Default(0) int actualHours,
    @Default(0) int exams,
    @Default(0) int deliveries,
    @Default(0) int stressLevel,
    @Default(0) double sleepHours,
    String? notes,
  }) = _WeeklyLoadDto;

  const WeeklyLoadDto._();

  factory WeeklyLoadDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyLoadDtoFromJson(json);

  WeeklyLoad toDomain() => WeeklyLoad(
    weekStart: PlannerJson.date(weekStart),
    plannedHours: plannedHours,
    actualHours: actualHours,
    exams: exams,
    deliveries: deliveries,
    stressLevel: stressLevel,
    sleepHours: sleepHours,
    notes: notes,
  );
}

@freezed
abstract class WeeklyLoadSyncDto with _$WeeklyLoadSyncDto {
  const factory WeeklyLoadSyncDto({
    required WeeklyLoadDto load,
    @Default(0) int xpAwarded,
  }) = _WeeklyLoadSyncDto;

  const WeeklyLoadSyncDto._();

  factory WeeklyLoadSyncDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyLoadSyncDtoFromJson(json);

  WeeklyLoadSync toDomain() =>
      WeeklyLoadSync(load: load.toDomain(), xpAwarded: xpAwarded);
}

@freezed
abstract class WeekBalanceDto with _$WeekBalanceDto {
  const factory WeekBalanceDto({
    required String weekStart,
    @Default(0) double plannedStudyHours,
    @Default(0) double actualStudyHours,
    @Default(0) double plannedSportHours,
    @Default(0) double actualSportHours,
    String? state,
  }) = _WeekBalanceDto;

  const WeekBalanceDto._();

  factory WeekBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$WeekBalanceDtoFromJson(json);

  WeekBalance toDomain() => WeekBalance(
    weekStart: PlannerJson.date(weekStart),
    plannedStudyHours: plannedStudyHours,
    actualStudyHours: actualStudyHours,
    plannedSportHours: plannedSportHours,
    actualSportHours: actualSportHours,
    state: BalanceState.fromApi(state),
  );
}

@freezed
abstract class TimelineItemDto with _$TimelineItemDto {
  const factory TimelineItemDto({
    String? kind,
    required String id,
    String? blockType,
    String? deadlineType,
    String? title,
    required String start,
    String? end,
    String? subjectId,
    String? subjectName,
    @Default(false) bool completed,
  }) = _TimelineItemDto;

  const TimelineItemDto._();

  factory TimelineItemDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineItemDtoFromJson(json);

  TimelineEntry toDomain() => TimelineEntry(
    kind: TimelineKind.fromApi(kind),
    id: id,
    blockType: blockType == null ? null : BlockType.fromApi(blockType),
    deadlineType: deadlineType == null
        ? null
        : DeadlineType.fromApi(deadlineType),
    title: title,
    start: PlannerJson.instant(start),
    end: PlannerJson.instantOrNull(end),
    subjectId: subjectId,
    subjectName: subjectName,
    completed: completed,
  );
}
