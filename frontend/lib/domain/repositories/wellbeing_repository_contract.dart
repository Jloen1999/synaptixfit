import '../models/reminders/reminder_options.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/cycle.dart';
import '../models/training/health_consent.dart';
import '../models/training/sport_activity.dart';
import '../models/training/today_adaptation.dart';
import '../models/training/training_page.dart';

/// Bienestar: seguimiento del ciclo (opcional), registro rápido y adaptación
/// de hoy, deporte hecho fuera de las rutinas y avisos opcionales.
abstract interface class WellbeingRepositoryContract {
  Future<AppResult<CycleOverview>> getCycle();

  Future<AppResult<CycleOverview>> changeCycleTracking({
    required bool enabled,
    bool consent = false,
    bool deleteHistory = false,
  });

  Future<AppResult<CycleOverview>> logCycleDay(CycleDay day);

  Future<AppResult<List<CycleDay>>> listCycleDays(DateTime from, DateTime to);

  Future<AppResult<Unit>> deleteCycleDay(DateTime date);

  Future<AppResult<Unit>> deleteCycleHistory();

  Future<AppResult<TodayAdaptation>> getTodayAdaptation();

  Future<AppResult<Unit>> submitQuickCheckIn(QuickCheckIn input);

  /// Permiso para guardar el registro diario (datos de salud, ADR 0034).
  Future<AppResult<HealthConsent>> getHealthConsent();

  Future<AppResult<Unit>> giveHealthConsent();

  Future<AppResult<Unit>> withdrawHealthConsent({required bool deleteRecords});

  Future<AppResult<TrainingPage<SportActivity>>> listSportActivities({
    int page = 0,
    int size = 20,
  });

  Future<AppResult<ReminderOptions>> getReminderOptions();

  Future<AppResult<ReminderOptions>> changeReminderOptions(
    ReminderOptions options,
  );
}
