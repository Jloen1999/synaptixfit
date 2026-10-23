import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/notification_repository_contract.dart';

/// Borra una notificación.
abstract interface class DeleteNotificationUseCaseContract {
  Future<AppResult<Unit>> call({required String notificationId});
}

class DeleteNotificationUseCase implements DeleteNotificationUseCaseContract {
  const DeleteNotificationUseCase(this._repository);

  final NotificationRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call({required String notificationId}) =>
      _repository.delete(notificationId);
}
