import '../../domain/models/reminders/reminder_options.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/cycle.dart';
import '../../domain/models/training/health_consent.dart';
import '../../domain/models/training/sport_activity.dart';
import '../../domain/models/training/today_adaptation.dart';
import '../../domain/models/training/training_page.dart';
import '../../domain/repositories/wellbeing_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/training/wellbeing_remote_data_source.dart';

/// Implementa [WellbeingRepositoryContract] con [WellbeingRemoteDataSource].
class WellbeingRepository implements WellbeingRepositoryContract {
  const WellbeingRepository(this._remote);

  final WellbeingRemoteDataSource _remote;

  @override
  Future<AppResult<CycleOverview>> getCycle() =>
      RepositoryErrorHandler.guard(_remote.getCycle);

  @override
  Future<AppResult<CycleOverview>> changeCycleTracking({
    required bool enabled,
    bool consent = false,
    bool deleteHistory = false,
  }) => RepositoryErrorHandler.guard(
    () => _remote.changeCycleTracking(
      enabled: enabled,
      consent: consent,
      deleteHistory: deleteHistory,
    ),
  );

  @override
  Future<AppResult<CycleOverview>> logCycleDay(CycleDay day) =>
      RepositoryErrorHandler.guard(() => _remote.logCycleDay(day));

  @override
  Future<AppResult<List<CycleDay>>> listCycleDays(DateTime from, DateTime to) =>
      RepositoryErrorHandler.guard(() => _remote.listCycleDays(from, to));

  @override
  Future<AppResult<Unit>> deleteCycleDay(DateTime date) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteCycleDay(date);
        return unit;
      });

  @override
  Future<AppResult<Unit>> deleteCycleHistory() =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteCycleHistory();
        return unit;
      });

  @override
  Future<AppResult<TodayAdaptation>> getTodayAdaptation() =>
      RepositoryErrorHandler.guard(_remote.getTodayAdaptation);

  @override
  Future<AppResult<Unit>> submitQuickCheckIn(QuickCheckIn input) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.submitQuickCheckIn(input);
        return unit;
      });

  @override
  Future<AppResult<HealthConsent>> getHealthConsent() =>
      RepositoryErrorHandler.guard(_remote.getHealthConsent);

  @override
  Future<AppResult<Unit>> giveHealthConsent() =>
      RepositoryErrorHandler.guard(() async {
        await _remote.giveHealthConsent();
        return unit;
      });

  @override
  Future<AppResult<Unit>> withdrawHealthConsent({
    required bool deleteRecords,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.withdrawHealthConsent(deleteRecords: deleteRecords);
    return unit;
  });

  @override
  Future<AppResult<TrainingPage<SportActivity>>> listSportActivities({
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () => _remote.listSportActivities(page: page, size: size),
  );

  @override
  Future<AppResult<ReminderOptions>> getReminderOptions() =>
      RepositoryErrorHandler.guard(_remote.getReminderOptions);

  @override
  Future<AppResult<ReminderOptions>> changeReminderOptions(
    ReminderOptions options,
  ) => RepositoryErrorHandler.guard(
    () => _remote.changeReminderOptions(options),
  );
}
