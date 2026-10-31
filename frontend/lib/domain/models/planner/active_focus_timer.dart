import '../../enums/planner_enums.dart';

/// Fase del Pomodoro en marcha o en pausa, guardada en el teléfono para que el
/// temporizador siga al salir de la pantalla y la fase se registre aunque la
/// app se cierre antes de terminar.
class ActiveFocusTimer {
  const ActiveFocusTimer({
    required this.phase,
    required this.running,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.completedFocusCycles,
    this.endsAt,
    this.subjectId,
    this.blockId,
    this.accountId,
  });

  final FocusPhase phase;

  /// Corriendo (con [endsAt]) o en pausa (con [remainingSeconds]).
  final bool running;
  final DateTime? endsAt;
  final int totalSeconds;
  final int remainingSeconds;
  final int completedFocusCycles;
  final String? subjectId;
  final String? blockId;

  /// Cuenta que la empezó: otra cuenta en el mismo teléfono no la hereda.
  final String? accountId;

  /// Segundos que quedan en [now]; 0 si ya terminó.
  int remainingAt(DateTime now) {
    final end = endsAt;
    if (!running || end == null) return remainingSeconds;
    final ms = end.difference(now).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }
}
