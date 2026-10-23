import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/social/app_notification.dart';
import '../models/social/social_page.dart';

/// Notificaciones in-app del usuario.
abstract interface class NotificationRepositoryContract {
  Future<AppResult<SocialPage<AppNotification>>> getNotifications({
    bool unreadOnly = false,
    int page = 0,
    int size = 20,
  });

  /// Total de notificaciones sin leer.
  Future<AppResult<int>> getUnreadCount();

  Future<AppResult<AppNotification>> markRead(String notificationId);

  /// Devuelve cuántas se han marcado.
  Future<AppResult<int>> markAllRead();

  Future<AppResult<Unit>> delete(String notificationId);
}
