import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/social/app_notification.dart';
import '../../domain/models/social/social_page.dart';
import '../../domain/repositories/notification_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/social/notification_remote_data_source.dart';

class NotificationRepository implements NotificationRepositoryContract {
  NotificationRepository(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<AppResult<SocialPage<AppNotification>>> getNotifications({
    bool unreadOnly = false,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.list(
      unreadOnly: unreadOnly,
      page: page,
      size: size,
    )).toDomain((dto) => dto.toDomain()),
  );

  @override
  Future<AppResult<int>> getUnreadCount() =>
      RepositoryErrorHandler.guard(_remote.unreadCount);

  @override
  Future<AppResult<AppNotification>> markRead(String notificationId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.markRead(notificationId)).toDomain(),
      );

  @override
  Future<AppResult<int>> markAllRead() =>
      RepositoryErrorHandler.guard(_remote.markAllRead);

  @override
  Future<AppResult<Unit>> delete(String notificationId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.delete(notificationId);
        return unit;
      });
}
