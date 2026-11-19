/// Cómo va la semana en «Tu semana» (`weekSummary.state`, ADR 0059): lo
/// decide el servidor con los mismos días que los círculos.
enum HomeWeekState {
  /// Nada planificado esta semana.
  noPlan,

  /// Lo que ya tocaba está hecho casi todo.
  onTrack,

  /// Se quedó sin hacer más de lo razonable.
  behind;

  /// `NO_PLAN`, `ON_TRACK` o `BEHIND` de la API; lo desconocido, «sin plan».
  static HomeWeekState fromApi(String? value) => switch (value) {
    'ON_TRACK' => onTrack,
    'BEHIND' => behind,
    _ => noPlan,
  };
}
