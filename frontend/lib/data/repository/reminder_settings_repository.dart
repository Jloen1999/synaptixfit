import 'dart:async';

import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/reminder_settings_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/reminder_settings_storage.dart';

/// Implementa [ReminderSettingsRepositoryContract] con [ReminderSettingsStorage]
/// y avisa de cada cambio para que el armazón resincronice los avisos.
class ReminderSettingsRepository implements ReminderSettingsRepositoryContract {
  ReminderSettingsRepository(this._storage);

  final ReminderSettingsStorage _storage;
  final _changes = StreamController<bool>.broadcast();

  @override
  Future<AppResult<bool>> isEnabled() =>
      RepositoryErrorHandler.guard(_storage.readEnabled);

  @override
  Future<AppResult<Unit>> setEnabled(bool enabled) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.writeEnabled(enabled);
        _changes.add(enabled);
        return unit;
      });

  @override
  Stream<bool> watchEnabled() => _changes.stream;
}
