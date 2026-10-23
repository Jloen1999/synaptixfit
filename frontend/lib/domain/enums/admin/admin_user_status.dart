/// Estado de las cuentas que muestra el buscador de usuarios.
enum AdminUserStatus {
  active,
  deleted,
  all;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminUserStatus fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminUserStatus.active,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminUserStatus> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
