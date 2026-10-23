import '../../models/reminders/reminder_composer.dart';
import '../../models/reminders/reminder_texts.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_plan_repository_contract.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';
import '../../repositories/reminder_settings_repository_contract.dart';

/// Sincroniza los avisos locales del móvil con el plan que decide el servidor
/// (repasos vencidos y bloques de los próximos días, ya filtrados por
/// preferencias y enfoque de uso). Devuelve cuántos avisos quedan programados.
abstract interface class SyncRemindersUseCaseContract {
  Future<AppResult<int>> call({required ReminderTexts texts});
}

/// Pide el plan a [ReminderPlanRepositoryContract], le pone textos e ids con
/// [ReminderComposer] y reemplaza los avisos de
/// [ReminderSchedulerRepositoryContract].
class SyncRemindersUseCase implements SyncRemindersUseCaseContract {
  const SyncRemindersUseCase({
    required this._scheduler,
    required this._settings,
    required this._plan,
    this._composer = const ReminderComposer(),
  });

  /// Ventana que se programa: la semana que viene.
  static const horizonDays = 7;

  final ReminderSchedulerRepositoryContract _scheduler;
  final ReminderSettingsRepositoryContract _settings;
  final ReminderPlanRepositoryContract _plan;
  final ReminderComposer _composer;

  @override
  Future<AppResult<int>> call({required ReminderTexts texts}) async {
    if (!_scheduler.isSupported) return const Success(0);
    final enabled = await _settings.isEnabled();
    if (enabled case Failure(:final error)) return Failure(error);
    if (enabled.valueOrNull != true) {
      return (await _scheduler.cancelAll()).map((_) => 0);
    }

    // Si el plan falla se devuelve el error sin tocar lo ya programado: mejor
    // avisos algo viejos que borrarlos por un fallo de red.
    final plan = await _plan.getPlan(days: horizonDays);
    if (plan case Failure(:final error)) return Failure(error);

    final reminders = _composer.compose(plan.valueOrNull!, texts);
    final scheduled = await _scheduler.replaceAll(
      reminders,
      channelName: texts.channelName,
    );
    return scheduled.map((_) => reminders.length);
  }
}
