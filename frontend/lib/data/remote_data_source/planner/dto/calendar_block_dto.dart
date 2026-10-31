import '../../../../domain/enums/item_time_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/calendar_block.dart';
import 'planner_json.dart';

part 'calendar_block_dto.freezed.dart';
part 'calendar_block_dto.g.dart';

@freezed
abstract class CalendarBlockDto with _$CalendarBlockDto {
  const factory CalendarBlockDto({
    required String id,
    String? type,
    required String start,
    required String end,
    String? subjectId,
    String? topics,
    String? location,
    String? priority,
    @Default(false) bool privateBlock,
    String? classKind,
    @Default(false) bool fixed,
    @Default(false) bool immovable,
    @Default(false) bool imported,
    @Default(false) bool hasConflict,
    @Default(false) bool completed,
    @Default(0) int xpReward,
    String? routineId,
    String? routineWeekId,
    String? routineDayId,
    String? challengeId,
    String? milestoneId,
    String? deadlineId,
    String? timeStatus,
    @Default(false) bool tracksPhysicalLoad,
  }) = _CalendarBlockDto;

  const CalendarBlockDto._();

  factory CalendarBlockDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarBlockDtoFromJson(json);

  CalendarBlock toDomain() => CalendarBlock(
    id: id,
    type: BlockType.fromApi(type),
    start: PlannerJson.instant(start),
    end: PlannerJson.instant(end),
    subjectId: subjectId,
    topics: topics,
    location: location,
    priority: PlannerPriority.fromApiOrNull(priority),
    privateBlock: privateBlock,
    classKind: ClassKind.fromApiOrNull(classKind),
    fixed: fixed,
    immovable: immovable,
    imported: imported,
    hasConflict: hasConflict,
    completed: completed,
    xpReward: xpReward,
    routineId: routineId,
    routineWeekId: routineWeekId,
    routineDayId: routineDayId,
    challengeId: challengeId,
    milestoneId: milestoneId,
    deadlineId: deadlineId,
    timeStatus: ItemTimeStatus.fromApi(timeStatus),
    tracksPhysicalLoad: tracksPhysicalLoad,
  );
}

@freezed
abstract class BlockChangeDto with _$BlockChangeDto {
  const factory BlockChangeDto({
    required CalendarBlockDto block,
    @Default(<CalendarBlockDto>[]) List<CalendarBlockDto> conflicts,
    @Default(0) int weeklyCopies,
  }) = _BlockChangeDto;

  const BlockChangeDto._();

  factory BlockChangeDto.fromJson(Map<String, dynamic> json) =>
      _$BlockChangeDtoFromJson(json);

  BlockChange toDomain() => BlockChange(
    block: block.toDomain(),
    conflicts: conflicts.map((c) => c.toDomain()).toList(),
    weeklyCopies: weeklyCopies,
  );
}

@freezed
abstract class BlockCompletionDto with _$BlockCompletionDto {
  const factory BlockCompletionDto({
    required CalendarBlockDto block,
    @Default(0) int xpDelta,
  }) = _BlockCompletionDto;

  const BlockCompletionDto._();

  factory BlockCompletionDto.fromJson(Map<String, dynamic> json) =>
      _$BlockCompletionDtoFromJson(json);

  BlockCompletion toDomain() =>
      BlockCompletion(block: block.toDomain(), xpDelta: xpDelta);
}

@freezed
abstract class ConflictDto with _$ConflictDto {
  const factory ConflictDto({
    required CalendarBlockDto first,
    required CalendarBlockDto second,
  }) = _ConflictDto;

  const ConflictDto._();

  factory ConflictDto.fromJson(Map<String, dynamic> json) =>
      _$ConflictDtoFromJson(json);

  BlockConflict toDomain() =>
      BlockConflict(first: first.toDomain(), second: second.toDomain());
}
