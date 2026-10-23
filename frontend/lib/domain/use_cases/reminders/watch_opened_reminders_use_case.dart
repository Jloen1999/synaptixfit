import '../../enums/reminder_kind.dart';
import '../../repositories/reminder_scheduler_repository_contract.dart';

/// Avisos locales que el usuario ha tocado, para llevarle a su pantalla.
abstract interface class WatchOpenedRemindersUseCaseContract {
  Stream<ReminderKind> call();
}

class WatchOpenedRemindersUseCase
    implements WatchOpenedRemindersUseCaseContract {
  const WatchOpenedRemindersUseCase(this._scheduler);

  final ReminderSchedulerRepositoryContract _scheduler;

  @override
  Stream<ReminderKind> call() =>
      _scheduler.isSupported ? _scheduler.watchOpened() : const Stream.empty();
}
