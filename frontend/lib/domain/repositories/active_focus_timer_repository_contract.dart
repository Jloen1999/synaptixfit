import '../models/planner/active_focus_timer.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Fase del Pomodoro en curso guardada en el teléfono (una como mucho).
abstract interface class ActiveFocusTimerRepositoryContract {
  /// La fase guardada o null si no hay ninguna.
  Future<AppResult<ActiveFocusTimer?>> load();

  Future<AppResult<Unit>> save(ActiveFocusTimer timer);

  Future<AppResult<Unit>> clear();
}
