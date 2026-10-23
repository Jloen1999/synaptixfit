/// Utilidades de semana del planificador (lunes a domingo, hora local).
abstract final class PlannerWeek {
  /// Lunes (00:00) de la semana que contiene [date].
  static DateTime mondayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  /// Lunes de la semana desplazada [weeks] semanas.
  static DateTime shift(DateTime weekStart, int weeks) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7 * weeks);

  /// Fecha del día [index] (0 = lunes) de la semana.
  static DateTime dayOf(DateTime weekStart, int index) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + index);

  /// Lunes siguiente (fin exclusivo de la semana).
  static DateTime endOf(DateTime weekStart) => shift(weekStart, 1);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
