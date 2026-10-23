/// Quién puede ver un contenido o perfil.
enum Visibility {
  private,
  friends,
  public;

  String get apiValue => name.toUpperCase();

  static Visibility fromApi(String? value) => Visibility.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => Visibility.private,
  );
}
