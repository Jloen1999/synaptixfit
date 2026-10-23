import '../models/planner/focus.dart';
import '../models/result/app_result.dart';

/// Sesiones de concentración (Pomodoro).
abstract interface class FocusRepositoryContract {
  /// Registra una fase terminada y devuelve la XP concedida.
  Future<AppResult<FocusSessionResult>> recordSession(
    FocusSessionRecord record,
  );

  /// Estadísticas de hoy y de su semana.
  Future<AppResult<FocusStats>> getStats();

  /// Duraciones recomendadas para hoy.
  Future<AppResult<FocusPlan>> getPlan();
}
