/// Magnitud con la que se mide un ejercicio.
enum AdminMeasurementType {
  repetitions,
  weight,
  time,
  distance,
  calories;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminMeasurementType fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminMeasurementType.repetitions,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminMeasurementType> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
