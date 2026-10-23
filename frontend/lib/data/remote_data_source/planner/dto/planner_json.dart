/// Conversión de fechas entre la API (ISO-8601 UTC / fecha `yyyy-MM-dd`) y el
/// dominio (hora local).
abstract final class PlannerJson {
  /// Instante ISO-8601 → hora local.
  static DateTime instant(String value) => DateTime.parse(value).toLocal();

  static DateTime? instantOrNull(String? value) =>
      value == null ? null : instant(value);

  /// Hora local → instante ISO-8601 UTC.
  static String toInstant(DateTime value) => value.toUtc().toIso8601String();

  /// Fecha `yyyy-MM-dd` → medianoche local.
  static DateTime date(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Fecha local → `yyyy-MM-dd`.
  static String toDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// Minutos desde medianoche → `HH:mm:ss`.
  static String toLocalTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}:00';
}
