import '../enums/weekly_email_status.dart';
import '../models/profile/notification_preferences.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Preferencias de notificaciones del usuario.
abstract interface class NotificationPreferencesRepositoryContract {
  Future<AppResult<NotificationPreferences>> getPreferences();

  Future<AppResult<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  );

  /// Resumen semanal por correo (ADR 0022).
  Future<AppResult<WeeklyEmailStatus>> getWeeklyEmail();

  Future<AppResult<WeeklyEmailStatus>> enableWeeklyEmail();

  Future<AppResult<Unit>> disableWeeklyEmail();
}
