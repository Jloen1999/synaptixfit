import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/reminder_kind.dart';
import '../../../../domain/models/reminders/reminder_plan.dart';

part 'reminder_plan_dto.freezed.dart';
part 'reminder_plan_dto.g.dart';

/// Respuesta de `GET /api/v1/notifications/reminder-plan`.
@freezed
abstract class ReminderPlanDto with _$ReminderPlanDto {
  const factory ReminderPlanDto({
    @Default(<ReminderPlanItemDto>[]) List<ReminderPlanItemDto> reminders,
  }) = _ReminderPlanDto;

  const ReminderPlanDto._();

  factory ReminderPlanDto.fromJson(Map<String, dynamic> json) =>
      _$ReminderPlanDtoFromJson(json);

  /// Un tipo que esta versión no conoce se descarta (el servidor puede añadir
  /// avisos nuevos antes de que se actualice la app).
  List<PlannedReminder> toDomain() =>
      reminders.map((r) => r.toDomain()).whereType<PlannedReminder>().toList();
}

/// Un aviso del plan; los instantes llegan en ISO-8601 UTC.
@freezed
abstract class ReminderPlanItemDto with _$ReminderPlanItemDto {
  const factory ReminderPlanItemDto({
    required String kind,
    required String at,
    required String refId,
    int? count,
    String? title,
    String? startsAt,
    String? targetId,
    String? place,
    @Default(<ReminderPlanTaskDto>[]) List<ReminderPlanTaskDto> tasks,
    ReminderPlanSummaryDto? summary,
  }) = _ReminderPlanItemDto;

  const ReminderPlanItemDto._();

  factory ReminderPlanItemDto.fromJson(Map<String, dynamic> json) =>
      _$ReminderPlanItemDtoFromJson(json);

  PlannedReminder? toDomain() {
    final reminderKind = ReminderKind.fromApi(kind);
    if (reminderKind == null) return null;
    return PlannedReminder(
      kind: reminderKind,
      at: DateTime.parse(at),
      refId: refId,
      count: count,
      title: title,
      startsAt: startsAt == null ? null : DateTime.parse(startsAt!),
      targetId: targetId,
      place: place,
      tasks: tasks.map((t) => t.toDomain()).toList(),
      summary: summary?.toDomain(),
    );
  }
}

/// Tarea de reto que menciona un aviso; `title` nulo: el propio reto.
@freezed
abstract class ReminderPlanTaskDto with _$ReminderPlanTaskDto {
  const factory ReminderPlanTaskDto({
    required String challengeId,
    String? challengeTitle,
    String? milestoneId,
    String? title,
  }) = _ReminderPlanTaskDto;

  const ReminderPlanTaskDto._();

  factory ReminderPlanTaskDto.fromJson(Map<String, dynamic> json) =>
      _$ReminderPlanTaskDtoFromJson(json);

  ReminderTask toDomain() => ReminderTask(
    challengeId: challengeId,
    challengeTitle: challengeTitle,
    milestoneId: milestoneId,
    title: title,
  );
}

/// Contenido del resumen de la mañana (solo en `MORNING_SUMMARY`).
@freezed
abstract class ReminderPlanSummaryDto with _$ReminderPlanSummaryDto {
  const factory ReminderPlanSummaryDto({
    @Default(0) int studies,
    @Default(0) int trainings,
    @Default(0) int classes,
    @Default(0) int personal,
    @Default(<ReminderPlanSummaryDeadlineDto>[])
    List<ReminderPlanSummaryDeadlineDto> deadlines,
    @Default(0) int tasks,
    @Default(false) bool checkIn,
  }) = _ReminderPlanSummaryDto;

  const ReminderPlanSummaryDto._();

  factory ReminderPlanSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ReminderPlanSummaryDtoFromJson(json);

  ReminderDaySummary toDomain() => ReminderDaySummary(
    studies: studies,
    trainings: trainings,
    classes: classes,
    personal: personal,
    deadlines: deadlines
        .map((d) => ReminderSummaryDeadline(title: d.title, exam: d.exam))
        .toList(),
    tasks: tasks,
    checkIn: checkIn,
  );
}

/// Entrega o examen del resumen de la mañana.
@freezed
abstract class ReminderPlanSummaryDeadlineDto
    with _$ReminderPlanSummaryDeadlineDto {
  const factory ReminderPlanSummaryDeadlineDto({
    String? title,
    @Default(false) bool exam,
  }) = _ReminderPlanSummaryDeadlineDto;

  factory ReminderPlanSummaryDeadlineDto.fromJson(Map<String, dynamic> json) =>
      _$ReminderPlanSummaryDeadlineDtoFromJson(json);
}
