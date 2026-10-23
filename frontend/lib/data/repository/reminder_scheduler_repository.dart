import '../../domain/enums/reminder_kind.dart';
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
  Stream<ReminderKind> watchOpened() =>
      RepositoryErrorHandler.guardStream(_local.watchOpenedPayloads)
          .map((result) => ReminderKind.fromPayload(result.valueOrNull))
          .where((kind) => kind != null)
          .cast<ReminderKind>();
}
