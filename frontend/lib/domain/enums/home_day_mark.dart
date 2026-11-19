/// Marca de un día en «Tu semana» (`planWeek[].mark`, ADR 0059). La decide el
/// servidor y se pinta con una forma que se entiende sin color.
enum HomeDayMark {
  /// Nada planificado ese día («–»).
  none,

  /// Todo hecho (✓).
  done,

  /// Algo hecho y algo por hacer (círculo medio lleno).
  partial,

  /// Algo se quedó sin hacer («!»).
  missed,

  /// Solo por hacer (el número de lo que queda).
  pending;

  /// `NONE`, `DONE`, `PARTIAL`, `MISSED` o `PENDING` de la API; lo
  /// desconocido, «nada planificado».
  static HomeDayMark fromApi(String? value) => switch (value) {
    'DONE' => done,
    'PARTIAL' => partial,
    'MISSED' => missed,
    'PENDING' => pending,
    _ => none,
  };
}
