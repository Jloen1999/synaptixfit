import '../../repositories/reminder_settings_repository_contract.dart';

/// Avisa cuando se activan o desactivan los recordatorios del dispositivo,
/// para volver a sincronizarlos al momento.
abstract interface class WatchDeviceRemindersEnabledUseCaseContract {
  Stream<bool> call();
}

class WatchDeviceRemindersEnabledUseCase
    implements WatchDeviceRemindersEnabledUseCaseContract {
  const WatchDeviceRemindersEnabledUseCase(this._settings);

  final ReminderSettingsRepositoryContract _settings;

  @override
  Stream<bool> call() => _settings.watchEnabled();
}
