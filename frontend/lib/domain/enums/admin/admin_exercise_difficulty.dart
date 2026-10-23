/// Dificultad de un ejercicio del catálogo.
enum AdminExerciseDifficulty {
  beginner,
  intermediate,
  advanced;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminExerciseDifficulty fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminExerciseDifficulty.beginner,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminExerciseDifficulty> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
