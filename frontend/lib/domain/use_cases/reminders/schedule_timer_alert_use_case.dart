import '../../models/reminders/timer_alert.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';

/// Programa el aviso de fin de fase del Pomodoro (sustituye al anterior). En
/// web no hace nada.
abstract interface class ScheduleTimerAlertUseCaseContract {
  Future<AppResult<Unit>> call(TimerAlert alert);
}

class ScheduleTimerAlertUseCase implements ScheduleTimerAlertUseCaseContract {
  const ScheduleTimerAlertUseCase(this._scheduler);

  final ReminderSchedulerRepositoryContract _scheduler;

  @override
  Future<AppResult<Unit>> call(TimerAlert alert) =>
      _scheduler.scheduleTimerAlert(alert);
}
