import '../../models/result/app_result.dart';
import '../../repositories/notification_repository_contract.dart';

/// Marca todas como leídas; devuelve cuántas.
abstract interface class MarkAllNotificationsReadUseCaseContract {
  Future<AppResult<int>> call();
}

class MarkAllNotificationsReadUseCase
    implements MarkAllNotificationsReadUseCaseContract {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationRepositoryContract _repository;

  @override
  Future<AppResult<int>> call() => _repository.markAllRead();
}
