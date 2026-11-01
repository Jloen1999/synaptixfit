import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Trinquete de valores visuales sueltos en las pantallas: tamaños de icono,
/// alturas de fila, opacidades y `TextStyle(...)` escritos a mano en vez de
/// tokens (`TokensSize.*`, `AppPill.tintAlpha`, `context.textStyles.*`).
///
/// El máximo solo puede BAJAR. Si arreglas apariciones, el test te dirá el
/// número nuevo: bájalo aquí en el mismo cambio. Si lo supera, usa un token
/// (o añade uno a `docs/05-design/tokens.json` y ejecuta
/// `dart run tool/generate_tokens.dart`); no subas el máximo.
const _maxAllowed = 102;

/// Patrones vigilados. `size:` y `minTileHeight:` solo con un número literal.
final _patterns = <String, RegExp>{
  'size: <número>': RegExp(r'\bsize:\s*\d'),
  'minTileHeight: <número>': RegExp(r'\bminTileHeight:\s*\d'),
  'withValues(alpha: 0.<n>)': RegExp(r'withValues\(alpha:\s*0?\.\d'),
  'TextStyle(': RegExp(r'(?<![A-Za-z0-9_])TextStyle\('),
};

void main() {
  test('las pantallas no suman valores visuales sueltos', () {
    final counts = <String, int>{};
    var total = 0;
    final files = Directory('lib/presentation/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // En los blocs `size:` es el tamaño de página de una consulta.
        .where((f) => !f.uri.pathSegments.contains('bloc'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final MapEntry(key: name, value: pattern) in _patterns.entries) {
        final n = pattern.allMatches(source).length;
        if (n == 0) continue;
        counts[name] = (counts[name] ?? 0) + n;
        total += n;
      }
    }

    expect(
      total,
      lessThanOrEqualTo(_maxAllowed),
      reason:
          'Hay $total valores sueltos (máximo $_maxAllowed): $counts. '
          'Usa tokens en lugar de números y estilos escritos a mano.',
    );
    // Recordatorio para bajar el trinquete cuando se arreglan apariciones.
    expect(
      total,
      _maxAllowed,
      reason:
          'Ahora hay $total valores sueltos: baja _maxAllowed a $total para '
          'que no vuelvan a subir.',
    );
  });
}
