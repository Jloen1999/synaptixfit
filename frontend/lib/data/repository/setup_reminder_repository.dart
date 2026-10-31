import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/setup_reminder_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/setup_reminder_storage.dart';

/// Implementa [SetupReminderRepositoryContract] con [SetupReminderStorage].
class SetupReminderRepository implements SetupReminderRepositoryContract {
  const SetupReminderRepository(this._storage);

  final SetupReminderStorage _storage;

  @override
  Future<AppResult<DateTime?>> snoozedUntil(String userId) =>
      RepositoryErrorHandler.guard(() async {
        final millis = await _storage.read(userId);
        return millis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(millis);
      });

  @override
  Future<AppResult<Unit>> snoozeUntil(String userId, DateTime until) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.write(userId, until.millisecondsSinceEpoch);
        return unit;
      });
}
