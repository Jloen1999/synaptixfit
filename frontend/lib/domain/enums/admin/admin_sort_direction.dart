/// Dirección de ordenación.
enum AdminSortDirection {
  asc,
  desc;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminSortDirection fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminSortDirection.desc,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminSortDirection> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
