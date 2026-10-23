import '../../models/profile/notification_preferences.dart';
import '../../models/result/app_result.dart';
import '../../repositories/notification_preferences_repository_contract.dart';

/// Guarda las preferencias de notificaciones.
abstract interface class UpdateNotificationPreferencesUseCaseContract {
  Future<AppResult<NotificationPreferences>> call(
    NotificationPreferences preferences,
  );
}

class UpdateNotificationPreferencesUseCase
    implements UpdateNotificationPreferencesUseCaseContract {
  const UpdateNotificationPreferencesUseCase(this._repository);

  final NotificationPreferencesRepositoryContract _repository;

  @override
  Future<AppResult<NotificationPreferences>> call(
    NotificationPreferences preferences,
  ) => _repository.updatePreferences(preferences);
}
