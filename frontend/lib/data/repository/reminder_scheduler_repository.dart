import '../../domain/models/reminders/ongoing_timer.dart';
import '../../domain/models/reminders/timer_alert.dart';
import '../../domain/models/reminders/reminder.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/reminder_scheduler_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/local_reminder_scheduler.dart';

/// Implementa [ReminderSchedulerRepositoryContract] con [LocalReminderScheduler] (plugin
/// en móvil, operación vacía en web) y traduce sus fallos a `AppError`.
class ReminderSchedulerRepository
    implements ReminderSchedulerRepositoryContract {
  const ReminderSchedulerRepository(this._local);

  final LocalReminderScheduler _local;

  @override
  bool get isSupported => _local.isSupported;

  @override
  Future<AppResult<bool>> requestPermission() =>
      RepositoryErrorHandler.guard(_local.requestPermission);

  @override
  Future<AppResult<bool>> hasPermission() =>
      RepositoryErrorHandler.guard(_local.hasPermission);

  @override
  Future<AppResult<Unit>> replaceAll(
    List<Reminder> reminders, {
    required String channelName,
  }) => RepositoryErrorHandler.guard(() async {
    await _local.replaceAll(reminders, channelName);
    return unit;
  });

  @override
  Future<AppResult<Unit>> cancelAll() => RepositoryErrorHandler.guard(() async {
    await _local.cancelAll();
    return unit;
  });

  /// Los fallos del plugin y los `payload` desconocidos se descartan: tocar un
  /// aviso nunca debe romper la app, como mucho no navega.

  @override
  Future<AppResult<Unit>> scheduleTimerAlert(TimerAlert alert) =>
      RepositoryErrorHandler.guard(() async {
        await _local.scheduleTimerAlert(alert);
        return unit;
      });

  @override
  Future<AppResult<Unit>> showOngoingTimer(OngoingTimer timer) =>
      RepositoryErrorHandler.guard(() async {
        await _local.showOngoingTimer(timer);
        return unit;
      });

  @override
  Future<AppResult<Unit>> cancelOngoingTimer() =>
      RepositoryErrorHandler.guard(() async {
        await _local.cancelOngoingTimer();
        return unit;
      });

  @override
  Future<AppResult<Unit>> cancelTimerAlert() =>
      RepositoryErrorHandler.guard(() async {
        await _local.cancelTimerAlert();
        return unit;
      });
  @override
  Stream<OpenedReminder> watchOpened() =>
      RepositoryErrorHandler.guardStream(_local.watchOpenedPayloads)
          .map((result) {
            final tap = result.valueOrNull;
            return OpenedReminder.fromPayload(
              tap?.payload,
              start: tap?.action == reminderStartAction,
            );
          })
          .where((opened) => opened != null)
          .cast<OpenedReminder>();
}
