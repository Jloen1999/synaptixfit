import '../../models/profile/notification_preferences.dart';
import '../../models/result/app_result.dart';
import '../../repositories/notification_preferences_repository_contract.dart';

/// Preferencias de notificaciones.
abstract interface class GetNotificationPreferencesUseCaseContract {
  Future<AppResult<NotificationPreferences>> call();
}

class GetNotificationPreferencesUseCase
    implements GetNotificationPreferencesUseCaseContract {
  const GetNotificationPreferencesUseCase(this._repository);

  final NotificationPreferencesRepositoryContract _repository;

  @override
  Future<AppResult<NotificationPreferences>> call() =>
      _repository.getPreferences();
}
