import '../../domain/models/reminders/reminder_plan.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/reminder_plan_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/reminders/reminder_plan_remote_data_source.dart';

/// Implementa [ReminderPlanRepositoryContract] con
/// [ReminderPlanRemoteDataSource].
class ReminderPlanRepository implements ReminderPlanRepositoryContract {
  const ReminderPlanRepository(this._remote);

  final ReminderPlanRemoteDataSource _remote;

  @override
  Future<AppResult<List<PlannedReminder>>> getPlan({required int days}) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.get(days: days)).toDomain(),
      );
}
