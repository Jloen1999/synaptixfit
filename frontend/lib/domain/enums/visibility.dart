/// Quién puede ver un contenido o perfil, de más a menos restrictivo.
enum Visibility {
  private,
  friends,
  public;

  String get apiValue => name.toUpperCase();

  /// Un contenido nunca se comparte más allá de la privacidad del perfil: el
  /// servidor lo rebaja igualmente; aquí solo sirve para no ofrecerlo.
  bool isAllowedBy(Visibility profile) => index <= profile.index;

  static Visibility fromApi(String? value) => Visibility.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => Visibility.private,
  );
}
