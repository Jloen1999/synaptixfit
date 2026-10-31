/// Convierte tarjetas al formato de texto que importa Anki (Archivo › Importar):
/// cabeceras `#separator`, `#html`, `#deck` y `#tags` y una tarjeta por línea
/// con anverso y reverso separados por tabulador. Los campos con tabulador,
/// salto de línea o comillas van entre comillas dobles (las internas, dobladas),
/// como admite el importador de Anki.
abstract final class AnkiExport {
  static const tag = 'synaptixfit';

  /// [cards]: pares (anverso, reverso).
  static String text(String deck, List<(String, String)> cards) {
    final lines = <String>[
      '#separator:tab',
      '#html:false',
      '#deck:${_singleLine(deck)}',
      '#tags:$tag',
      for (final (front, back) in cards) '${_field(front)}\t${_field(back)}',
    ];
    return '${lines.join('\n')}\n';
  }

  /// Nombre del fichero a partir del mazo, para que cada material tenga el
  /// suyo: `synaptixfit-algebra-lineal.txt`.
  static String fileName(String deck) {
    final slug = _singleLine(deck)
        .toLowerCase()
        .replaceAll(RegExp('[áàä]'), 'a')
        .replaceAll(RegExp('[éèë]'), 'e')
        .replaceAll(RegExp('[íìï]'), 'i')
        .replaceAll(RegExp('[óòö]'), 'o')
        .replaceAll(RegExp('[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final short = slug.length > 60 ? slug.substring(0, 60) : slug;
    return short.isEmpty ? 'synaptixfit.txt' : 'synaptixfit-$short.txt';
  }

  /// Entre comillas si lleva separadores o si empieza por `#` (Anki tomaría la
  /// línea por una cabecera).
  static String _field(String value) {
    final v = value.trim();
    if (v.startsWith('#') || v.contains(RegExp('[\t\n\r"]'))) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String _singleLine(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
