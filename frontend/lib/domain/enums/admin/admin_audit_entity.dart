/// Tipo de entidad afectada por una acción auditada.
enum AdminAuditEntity {
  user,
  platformSettings,
  exercise,
  socialPost,
  comment,
  other;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminAuditEntity fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminAuditEntity.other,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminAuditEntity> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
