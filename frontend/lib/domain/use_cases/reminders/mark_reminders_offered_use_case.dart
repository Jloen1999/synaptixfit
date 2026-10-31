import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_settings_repository_contract.dart';

/// Recuerda en el dispositivo que ya se ofrecieron los recordatorios (se acepte
/// o no), para no volver a preguntar.
abstract interface class MarkRemindersOfferedUseCaseContract {
  Future<AppResult<Unit>> call();
}

class MarkRemindersOfferedUseCase
    implements MarkRemindersOfferedUseCaseContract {
  const MarkRemindersOfferedUseCase(this._settings);

  final ReminderSettingsRepositoryContract _settings;

  @override
  Future<AppResult<Unit>> call() => _settings.markOffered();
}
