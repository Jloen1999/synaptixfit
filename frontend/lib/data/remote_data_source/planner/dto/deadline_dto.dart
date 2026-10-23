import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/deadline.dart';
import 'planner_json.dart';

part 'deadline_dto.freezed.dart';
part 'deadline_dto.g.dart';

@freezed
abstract class DeadlineDto with _$DeadlineDto {
  const factory DeadlineDto({
    required String id,
    required String title,
    String? type,
    required String dueAt,
    String? difficulty,
    String? description,
    String? subjectId,
    @Default(false) bool completed,
    @Default(false) bool imported,
  }) = _DeadlineDto;

  const DeadlineDto._();

  factory DeadlineDto.fromJson(Map<String, dynamic> json) =>
      _$DeadlineDtoFromJson(json);

  Deadline toDomain() => Deadline(
    id: id,
    title: title,
    type: DeadlineType.fromApi(type),
    dueAt: PlannerJson.instant(dueAt),
    difficulty:
        PlannerPriority.fromApiOrNull(difficulty) ?? PlannerPriority.medium,
    description: description,
    subjectId: subjectId,
    completed: completed,
    imported: imported,
  );
}

@freezed
abstract class DeadlinePageDto with _$DeadlinePageDto {
  const factory DeadlinePageDto({
    @Default(<DeadlineDto>[]) List<DeadlineDto> items,
    @Default(0) int page,
    @Default(0) int totalPages,
  }) = _DeadlinePageDto;

  const DeadlinePageDto._();

  factory DeadlinePageDto.fromJson(Map<String, dynamic> json) =>
      _$DeadlinePageDtoFromJson(json);

  DeadlinePage toDomain() => DeadlinePage(
    items: items.map((d) => d.toDomain()).toList(),
    page: page,
    totalPages: totalPages,
  );
}

@freezed
abstract class DeadlineCompletionDto with _$DeadlineCompletionDto {
  const factory DeadlineCompletionDto({
    required DeadlineDto deadline,
    @Default(0) int xpDelta,
  }) = _DeadlineCompletionDto;

  const DeadlineCompletionDto._();

  factory DeadlineCompletionDto.fromJson(Map<String, dynamic> json) =>
      _$DeadlineCompletionDtoFromJson(json);

  DeadlineCompletion toDomain() =>
      DeadlineCompletion(deadline: deadline.toDomain(), xpDelta: xpDelta);
}
