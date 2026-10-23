import '../../models/result/app_result.dart';
import '../../models/social/app_notification.dart';
import '../../repositories/notification_repository_contract.dart';

/// Marca una notificación como leída.
abstract interface class MarkNotificationReadUseCaseContract {
  Future<AppResult<AppNotification>> call({required String notificationId});
}

class MarkNotificationReadUseCase
    implements MarkNotificationReadUseCaseContract {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationRepositoryContract _repository;

  @override
  Future<AppResult<AppNotification>> call({required String notificationId}) =>
      _repository.markRead(notificationId);
}
