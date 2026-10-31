import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';
import '../../repositories/reminder_settings_repository_contract.dart';

/// ¿Conviene ofrecer ahora los recordatorios? Solo una vez por dispositivo, si
/// los admite y aún no están activados: escondidos en Ajustes casi nadie los
/// encontraba y el repaso espaciado no funciona si nadie avisa.
abstract interface class ShouldOfferRemindersUseCaseContract {
  Future<AppResult<bool>> call();
}

class ShouldOfferRemindersUseCase
    implements ShouldOfferRemindersUseCaseContract {
  const ShouldOfferRemindersUseCase({
    required this._scheduler,
    required this._settings,
  });

  final ReminderSchedulerRepositoryContract _scheduler;
  final ReminderSettingsRepositoryContract _settings;

  @override
  Future<AppResult<bool>> call() async {
    if (!_scheduler.isSupported) return const Success(false);
    final enabled = await _settings.isEnabled();
    if (enabled case Failure(:final error)) return Failure(error);
    if (enabled.valueOrNull ?? false) return const Success(false);
    final offered = await _settings.wasOffered();
    return offered.map((value) => !value);
  }
}
