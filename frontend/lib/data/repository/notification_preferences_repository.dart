import '../../domain/models/profile/notification_preferences.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/notification_preferences_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/profile/dto/notification_preferences_dto.dart';
import '../remote_data_source/profile/notification_preferences_remote_data_source.dart';

class NotificationPreferencesRepository
    implements NotificationPreferencesRepositoryContract {
  NotificationPreferencesRepository(this._remote);

  final NotificationPreferencesRemoteDataSource _remote;

  @override
  Future<AppResult<NotificationPreferences>> getPreferences() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.get()).toDomain(),
      );

  @override
  Future<AppResult<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.update(
      notificationPreferencesToJson(preferences),
    )).toDomain(),
  );
}
