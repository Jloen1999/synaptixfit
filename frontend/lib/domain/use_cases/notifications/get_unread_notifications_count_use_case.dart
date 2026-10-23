import '../../models/result/app_result.dart';
import '../../repositories/notification_repository_contract.dart';

/// Total de notificaciones sin leer.
abstract interface class GetUnreadNotificationsCountUseCaseContract {
  Future<AppResult<int>> call();
}

class GetUnreadNotificationsCountUseCase
    implements GetUnreadNotificationsCountUseCaseContract {
  const GetUnreadNotificationsCountUseCase(this._repository);

  final NotificationRepositoryContract _repository;

  @override
  Future<AppResult<int>> call() => _repository.getUnreadCount();
}
