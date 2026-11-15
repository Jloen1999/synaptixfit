/// «Hoy toca: suave / normal / fuerte» en «Tu día» (ADR 0042). Lo decide el
/// servidor con la adaptación de hoy y el registro diario; el cliente pinta.
enum TodayIntensity {
  easy,
  normal,
  hard;

  /// `EASY`, `NORMAL` o `HARD` de la API; nulo si no llega o no se conoce.
  static TodayIntensity? fromApi(String? value) => switch (value) {
    'EASY' => easy,
    'NORMAL' => normal,
    'HARD' => hard,
    _ => null,
  };
}
