import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';

/// Borra todos los avisos locales (al cerrar sesión, para que el siguiente
/// usuario del teléfono no reciba los del anterior).
abstract interface class ClearRemindersUseCaseContract {
  Future<AppResult<Unit>> call();
}

class ClearRemindersUseCase implements ClearRemindersUseCaseContract {
  const ClearRemindersUseCase(this._scheduler);

  final ReminderSchedulerRepositoryContract _scheduler;

  @override
  Future<AppResult<Unit>> call() async =>
      _scheduler.isSupported ? _scheduler.cancelAll() : const Success(unit);
}
