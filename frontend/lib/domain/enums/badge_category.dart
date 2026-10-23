/// Categoría de una insignia del catálogo.
enum BadgeCategory {
  training,
  study,
  social,
  streak,
  special;

  /// Valor que espera la API (`TRAINING`, `STUDY`…).
  String get apiValue => name.toUpperCase();

  static BadgeCategory fromApi(String? value) => BadgeCategory.values
      .firstWhere((c) => c.apiValue == value, orElse: () => special);
}
