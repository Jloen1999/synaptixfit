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
    );
  }
}
