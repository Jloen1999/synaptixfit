/// Zona del ratio de carga aguda:crónica (ACWR) del inicio.
enum HomeAcwrZone {
  noData,
  undertraining,
  optimal,
  danger,
  overtraining;

  bool get isRisky => this == danger || this == overtraining;

  static HomeAcwrZone fromApi(String? value) => switch (value) {
    'UNDERTRAINING' => undertraining,
    'OPTIMAL' => optimal,
    'DANGER' => danger,
    'OVERTRAINING' => overtraining,
    _ => noData,
  };
}
