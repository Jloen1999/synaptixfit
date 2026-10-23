import '../models/profile/notification_preferences.dart';
import '../models/result/app_result.dart';

/// Preferencias de notificaciones del usuario.
abstract interface class NotificationPreferencesRepositoryContract {
  Future<AppResult<NotificationPreferences>> getPreferences();

  Future<AppResult<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  );
}
