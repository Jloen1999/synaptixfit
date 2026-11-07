/// Cuándo avisar de una tarea de reto con fecha (ADR 0035). [apiValue] es su
/// nombre en `/notifications/reminder-options`.
enum ReminderTaskTiming {
  /// La tarde anterior (por defecto).
  eveningBefore('EVENING_BEFORE'),

  /// La mañana del mismo día.
  morningOf('MORNING_OF');

  const ReminderTaskTiming(this.apiValue);

  final String apiValue;

  static ReminderTaskTiming? fromApi(String? value) {
    for (final v in values) {
      if (v.apiValue == value) return v;
    }
    return null;
  }
}
