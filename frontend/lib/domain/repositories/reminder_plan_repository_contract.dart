import '../models/reminders/reminder_plan.dart';
import '../models/result/app_result.dart';

/// Plan de recordatorios del móvil que decide el servidor (ADR 0013).
abstract interface class ReminderPlanRepositoryContract {
  /// Avisos de los próximos [days] días (1..7), ordenados por hora.
  Future<AppResult<List<PlannedReminder>>> getPlan({required int days});
}
