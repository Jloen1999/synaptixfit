import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/notification_message_code.dart';
import '../../../../domain/enums/notification_priority.dart';
import '../../../../domain/enums/notification_type.dart';
import '../../../../domain/models/social/app_notification.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

/// Notificación in-app (`NotificationResponse`).
@freezed
abstract class NotificationDto with _$NotificationDto {
  const factory NotificationDto({
    required String id,
    @Default('') String title,
    String? description,
    String? priority,
    String? type,
    String? actionUrl,
    String? actionLabel,
    @Default(false) bool read,
    required DateTime createdAt,
    String? messageCode,
    Map<String, dynamic>? messageParams,
  }) = _NotificationDto;

  const NotificationDto._();

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  AppNotification toDomain() => AppNotification(
    id: id,
    title: title,
    description: description,
    priority: NotificationPriority.fromApi(priority),
    type: NotificationType.fromApi(type),
    actionUrl: actionUrl == null || actionUrl!.trim().isEmpty
        ? null
        : actionUrl,
    actionLabel: actionLabel,
    read: read,
    createdAt: createdAt.toLocal(),
    messageCode: NotificationMessageCode.fromApi(messageCode),
    messageParams: {
      for (final e in (messageParams ?? const <String, dynamic>{}).entries)
        if (e.value != null) e.key: '${e.value}',
    },
  );
}
