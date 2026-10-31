import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/notification_message_code.dart';
import '../../enums/notification_priority.dart';
import '../../enums/notification_type.dart';

part 'app_notification.freezed.dart';

/// Notificación in-app con enlace profundo opcional ([actionUrl]). Con
/// [messageCode] la app muestra su propio texto (en su idioma) con
/// [messageParams]; [title] y [description] son el respaldo.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String title,
    String? description,
    required NotificationPriority priority,
    required NotificationType type,
    String? actionUrl,
    String? actionLabel,
    required bool read,
    required DateTime createdAt,
    NotificationMessageCode? messageCode,
    @Default(<String, String>{}) Map<String, String> messageParams,
  }) = _AppNotification;
}
