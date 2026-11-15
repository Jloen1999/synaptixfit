import '../models/planner/focus.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Última elección de descansos del Pomodoro ([FocusBreakChoice]), guardada en
/// el teléfono (ADR 0053).
abstract interface class FocusBreakChoiceRepositoryContract {
  /// Vacía (los recomendados) si no hay nada guardado.
  Future<AppResult<FocusBreakChoice>> load();

  /// Sustituye lo guardado; una elección vacía lo borra.
  Future<AppResult<Unit>> save(FocusBreakChoice choice);
}
