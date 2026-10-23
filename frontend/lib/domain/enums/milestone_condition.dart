/// Condición de desbloqueo de una tarea con dependencias.
enum MilestoneCondition {
  /// Todas las dependencias completadas (AND).
  all,

  /// Al menos una dependencia completada (OR).
  any,

  /// Al menos N de las dependencias completadas (X de Y).
  xOfY,
}
