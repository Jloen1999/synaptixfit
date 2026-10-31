import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';

/// Quita el aviso de fin de fase del Pomodoro (al pausar, saltar o salir).
abstract interface class CancelTimerAlertUseCaseContract {
  Future<AppResult<Unit>> call();
}

class CancelTimerAlertUseCase implements CancelTimerAlertUseCaseContract {
  const CancelTimerAlertUseCase(this._scheduler);

  final ReminderSchedulerRepositoryContract _scheduler;

  @override
  Future<AppResult<Unit>> call() => _scheduler.cancelTimerAlert();
}
