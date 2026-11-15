/// En qué punto está el día en «Tu día» (`todaySummary.state`, ADR 0050). Lo
/// decide el servidor con los mismos eventos que la agenda.
enum HomeDayState {
  /// Nada de hoy que cuente (como mucho clases, comidas o descansos).
  nothingPlanned,

  /// Queda algo en curso o por empezar.
  pending,

  /// Lo que queda ya pasó sin hacerse: aún se puede marcar.
  missedLeft,

  /// Todo lo que cuenta está hecho.
  allDone;

  /// `NOTHING_PLANNED`, `PENDING`, `MISSED_LEFT` o `ALL_DONE` de la API; lo
  /// desconocido se trata como «nada planificado».
  static HomeDayState fromApi(String? value) => switch (value) {
    'PENDING' => pending,
    'MISSED_LEFT' => missedLeft,
    'ALL_DONE' => allDone,
    _ => nothingPlanned,
  };
}
