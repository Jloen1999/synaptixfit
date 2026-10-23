/// Finalidad de entrenamiento de un ejercicio.
enum AdminExercisePurpose {
  hypertrophy,
  maxStrength,
  power,
  strengthEndurance,
  mobility,
  stability,
  metabolicConditioning;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminExercisePurpose fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminExercisePurpose.hypertrophy,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminExercisePurpose> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
