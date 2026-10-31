import '../../models/reminders/ongoing_timer.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';

/// Muestra o actualiza la notificación fija del Pomodoro; con null la quita.
/// En web no hace nada.
abstract interface class UpdateOngoingTimerUseCaseContract {
  Future<AppResult<Unit>> call(OngoingTimer? timer);
}

class UpdateOngoingTimerUseCase implements UpdateOngoingTimerUseCaseContract {
  const UpdateOngoingTimerUseCase(this._scheduler);

  final ReminderSchedulerRepositoryContract _scheduler;

  @override
  Future<AppResult<Unit>> call(OngoingTimer? timer) => timer == null
      ? _scheduler.cancelOngoingTimer()
      : _scheduler.showOngoingTimer(timer);
}
