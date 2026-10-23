import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/profile/notification_category.dart';
import '../../enums/profile/notification_mode.dart';

part 'notification_preferences.freezed.dart';

/// Hora del día sin fecha (horas de silencio).
@freezed
abstract class ClockTime with _$ClockTime {
  const factory ClockTime({required int hour, required int minute}) =
      _ClockTime;

  const ClockTime._();

  /// Formato `HH:mm:ss` que espera la API.
  String get apiValue => '${_two(hour)}:${_two(minute)}:00';

  /// Lee `HH:mm` o `HH:mm:ss`; devuelve `null` si no es válida.
  static ClockTime? tryParse(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return ClockTime(hour: hour, minute: minute);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// Preferencias de notificaciones del usuario.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required Set<NotificationCategory> activeCategories,
    ClockTime? quietHoursStart,
    ClockTime? quietHoursEnd,
    required int dailyLimit,
    required NotificationMode mode,
  }) = _NotificationPreferences;
}
