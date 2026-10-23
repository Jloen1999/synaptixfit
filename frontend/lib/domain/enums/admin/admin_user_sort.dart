/// Campo de ordenación del listado de usuarios.
enum AdminUserSort {
  createdAt('CREATED_AT'),
  level('LEVEL'),
  xp('XP'),
  fullName('NAME'),
  streak('STREAK');

  const AdminUserSort(this.apiValue);

  /// Valor que espera la API.
  final String apiValue;

  static AdminUserSort fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminUserSort.createdAt,
  );
}
