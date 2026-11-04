/// Textos legales públicos (ADR 0034). [slug] es su nombre en la API.
enum LegalDocumentKind {
  privacy('privacy'),
  terms('terms'),
  accountDeletion('account-deletion');

  const LegalDocumentKind(this.slug);

  final String slug;

  /// Desde el nombre de la ruta; `null` si no existe.
  static LegalDocumentKind? fromSlug(String? value) {
    for (final kind in values) {
      if (kind.slug == value) return kind;
    }
    return null;
  }
}
