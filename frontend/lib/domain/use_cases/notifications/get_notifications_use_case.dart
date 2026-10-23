import '../../models/result/app_result.dart';
import '../../models/social/app_notification.dart';
import '../../models/social/social_page.dart';
import '../../repositories/notification_repository_contract.dart';

/// Notificaciones del usuario (más recientes primero).
abstract interface class GetNotificationsUseCaseContract {
  Future<AppResult<SocialPage<AppNotification>>> call({
    bool unreadOnly = false,
    int page = 0,
    int size = 20,
  });
}

class GetNotificationsUseCase implements GetNotificationsUseCaseContract {
  const GetNotificationsUseCase(this._repository);

  final NotificationRepositoryContract _repository;

  @override
  Future<AppResult<SocialPage<AppNotification>>> call({
    bool unreadOnly = false,
    int page = 0,
    int size = 20,
  }) => _repository.getNotifications(
    unreadOnly: unreadOnly,
    page: page,
    size: size,
  );
}
