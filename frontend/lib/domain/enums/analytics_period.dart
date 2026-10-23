/// Ventana temporal de la analítica.
enum AnalyticsPeriod {
  /// Últimas 4 semanas.
  weekly(4),

  /// Últimas 12 semanas.
  monthly(12),

  /// Últimas 26 semanas.
  quarterly(26);

  const AnalyticsPeriod(this.weeks);

  final int weeks;

  String get apiValue => name.toUpperCase();

  static AnalyticsPeriod fromApi(String? value) => AnalyticsPeriod.values
      .firstWhere((p) => p.apiValue == value, orElse: () => monthly);
}
