/// Estado de un bloque o una entrega respecto a «ahora», tal como lo decide el
/// servidor (`ItemTimeStatus`): lo que pasó sin hacerse queda [missed].
enum ItemTimeStatus {
  upcoming,
  inProgress,
  done,

  /// Bloque que terminó sin hacerse, o entrega vencida sin completar.
  missed,

  /// Pasado sin seguimiento (descanso, comida, sueño…).
  past;

  static ItemTimeStatus fromApi(String? value) => switch (value) {
    'IN_PROGRESS' => inProgress,
    'DONE' => done,
    'MISSED' => missed,
    'PAST' => past,
    _ => upcoming,
  };
}
