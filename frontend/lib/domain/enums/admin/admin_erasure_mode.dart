/// Modo de borrado aplicado a una cuenta.
enum AdminErasureMode {
  contentWiped,
  anonymized,
  deleted;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminErasureMode fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminErasureMode.deleted,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminErasureMode> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
