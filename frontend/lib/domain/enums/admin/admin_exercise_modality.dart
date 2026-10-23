/// Modalidad de un ejercicio del catálogo.
enum AdminExerciseModality {
  strength,
  mobility,
  metabolic,
  aerobic;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminExerciseModality fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminExerciseModality.strength,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminExerciseModality> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
