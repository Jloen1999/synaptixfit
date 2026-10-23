/// Tipo de resultado del centro de generación multi-fuente.
enum ArtifactKind {
  summary('SUMMARY'),
  mindMap('MIND_MAP'),
  flashcards('FLASHCARDS'),
  practiceTest('PRACTICE_TEST');

  const ArtifactKind(this.apiValue);

  /// Valor que usa la API.
  final String apiValue;

  static ArtifactKind fromApi(String? value) => ArtifactKind.values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => ArtifactKind.summary,
  );
}
