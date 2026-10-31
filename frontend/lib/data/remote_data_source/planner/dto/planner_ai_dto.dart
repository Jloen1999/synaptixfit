import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/planner_ai.dart';
import 'planner_json.dart';

part 'planner_ai_dto.freezed.dart';
part 'planner_ai_dto.g.dart';

@freezed
abstract class SuggestedBlockDto with _$SuggestedBlockDto {
  const factory SuggestedBlockDto({
    String? type,
    required String start,
    required String end,
    String? subjectId,
    String? subjectName,
    String? routineId,
    String? routineName,
    String? topic,
  }) = _SuggestedBlockDto;

  const SuggestedBlockDto._();

  factory SuggestedBlockDto.fromJson(Map<String, dynamic> json) =>
      _$SuggestedBlockDtoFromJson(json);

  SuggestedBlock toDomain() => SuggestedBlock(
    type: BlockType.fromApi(type),
    start: PlannerJson.instant(start),
    end: PlannerJson.instant(end),
    subjectId: subjectId,
    subjectName: subjectName,
    routineId: routineId,
    routineName: routineName,
    topic: topic,
  );
}

@freezed
abstract class SuggestionDto with _$SuggestionDto {
  const factory SuggestionDto({
    String? source,
    @Default(0) double studyHours,
    @Default(0) int sportSessions,
    @Default(<SuggestedBlockDto>[]) List<SuggestedBlockDto> blocks,
  }) = _SuggestionDto;

  const SuggestionDto._();

  factory SuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$SuggestionDtoFromJson(json);

  WeekSuggestion toDomain() => WeekSuggestion(
    source: SuggestionSource.fromApi(source),
    studyHours: studyHours,
    sportSessions: sportSessions,
    blocks: blocks.map((b) => b.toDomain()).toList(),
  );
}

@freezed
abstract class ScheduleScanDto with _$ScheduleScanDto {
  const factory ScheduleScanDto({
    @Default(0) int classesFound,
    @Default(0) int blocksCreated,
    @Default(0) int blocksUpdated,
    @Default(<String>[]) List<String> unmatchedSubjects,
    @Default(<ScheduleClassDto>[]) List<ScheduleClassDto> classes,
  }) = _ScheduleScanDto;

  const ScheduleScanDto._();

  factory ScheduleScanDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleScanDtoFromJson(json);

  ScheduleScanResult toDomain() => ScheduleScanResult(
    classesFound: classesFound,
    blocksCreated: blocksCreated,
    blocksUpdated: blocksUpdated,
    unmatchedSubjects: unmatchedSubjects,
    classes: classes.map((c) => c.toDomain()).toList(),
  );
}

@freezed
abstract class ScheduleClassDto with _$ScheduleClassDto {
  const factory ScheduleClassDto({
    @Default('') String subjectName,
    String? classKind,
    @Default(1) int dayOfWeek,
    @Default('') String start,
    @Default('') String end,
    String? room,
  }) = _ScheduleClassDto;

  const ScheduleClassDto._();

  factory ScheduleClassDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleClassDtoFromJson(json);

  /// La API manda las horas como «HH:mm:ss»: se muestran como «HH:mm».
  ScheduleClass toDomain() => ScheduleClass(
    subjectName: subjectName,
    dayOfWeek: dayOfWeek,
    start: _hm(start),
    end: _hm(end),
    practice: classKind == 'PRACTICE',
    room: room,
  );

  static String _hm(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;
}

@freezed
abstract class IcsImportDto with _$IcsImportDto {
  const factory IcsImportDto({
    String? match,
    @Default(0) int totalEvents,
    @Default(0) int matchingEvents,
    @Default(0) int classes,
    @Default(0) int exams,
    @Default(0) int deliveries,
    @Default(0) int created,
    @Default(0) int updated,
    @Default(false) bool imported,
  }) = _IcsImportDto;

  const IcsImportDto._();

  factory IcsImportDto.fromJson(Map<String, dynamic> json) =>
      _$IcsImportDtoFromJson(json);

  IcsImportResult toDomain() => IcsImportResult(
    match: IcsMatch.fromApi(match),
    totalEvents: totalEvents,
    matchingEvents: matchingEvents,
    classes: classes,
    exams: exams,
    deliveries: deliveries,
    created: created,
    updated: updated,
    imported: imported,
  );
}
