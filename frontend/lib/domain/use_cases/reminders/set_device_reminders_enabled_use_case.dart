import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';
import '../../repositories/reminder_settings_repository_contract.dart';

/// Activa o desactiva los recordatorios en este dispositivo. Al activar pide
/// permiso al sistema; devuelve cómo queda (`false` si se negó el permiso).
abstract interface class SetDeviceRemindersEnabledUseCaseContract {
  Future<AppResult<bool>> call(bool enabled);
}

class SetDeviceRemindersEnabledUseCase
    implements SetDeviceRemindersEnabledUseCaseContract {
  const SetDeviceRemindersEnabledUseCase({
    required this._scheduler,
    required this._settings,
  });

  final ReminderSchedulerRepositoryContract _scheduler;
  final ReminderSettingsRepositoryContract _settings;

  @override
  Future<AppResult<bool>> call(bool enabled) async {
    if (!_scheduler.isSupported) return const Success(false);
    if (!enabled) {
      final saved = await _settings.setEnabled(false);
      if (saved case Failure(:final error)) return Failure(error);
      return (await _scheduler.cancelAll()).map((_) => false);
    }
    final permission = await _scheduler.requestPermission();
    if (permission case Failure(:final error)) return Failure(error);
    final granted = permission.valueOrNull ?? false;
    return (await _settings.setEnabled(granted)).map((_) => granted);
  }
}
