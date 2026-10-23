import '../../models/reminders/reminder.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';
import '../../repositories/reminder_settings_repository_contract.dart';

/// Si este dispositivo admite recordatorios, si están activados en él y si el
/// sistema sigue dando permiso para mostrarlos.
abstract interface class GetDeviceRemindersStatusUseCaseContract {
  Future<AppResult<DeviceRemindersStatus>> call();
}

class GetDeviceRemindersStatusUseCase
    implements GetDeviceRemindersStatusUseCaseContract {
  const GetDeviceRemindersStatusUseCase({
    required this._scheduler,
    required this._settings,
  });

  final ReminderSchedulerRepositoryContract _scheduler;
  final ReminderSettingsRepositoryContract _settings;

  @override
  Future<AppResult<DeviceRemindersStatus>> call() async {
    if (!_scheduler.isSupported) {
      return const Success(
        DeviceRemindersStatus(supported: false, enabled: false),
      );
    }
    final enabled = await _settings.isEnabled();
    if (enabled case Failure(:final error)) return Failure(error);
    // El permiso puede retirarse en los ajustes del teléfono. Si no se puede
    // consultar, se da por concedido para no alarmar sin motivo.
    final permission = (await _scheduler.hasPermission()).valueOrNull ?? true;
    return Success(
      DeviceRemindersStatus(
        supported: true,
        enabled: enabled.valueOrNull ?? false,
        permissionGranted: permission,
      ),
    );
  }
}
