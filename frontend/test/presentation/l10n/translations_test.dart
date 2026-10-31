import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Cada idioma (app_en/fr/pt.arb, generados por tool/merge_arb.dart) trae
/// todas las claves del español con los mismos marcadores: una clave sin
/// traducir saldría en español y un marcador perdido rompería el texto.
void main() {
  const languages = ['en', 'fr', 'pt'];
  final icu = RegExp(r'\{\s*([A-Za-z_]\w*)\s*,\s*(plural|select)\s*,');
  // Un {palabra} pegado a una etiqueta de caso (=0{Hoy}, wed{X}) es texto.
  final simple = RegExp(r'(?<![=\w])\{\s*([A-Za-z_]\w*)\s*\}');

  Map<String, String> load(String language) {
    final file = File('lib/presentation/l10n/app_$language.arb');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final e in data.entries)
        if (!e.key.startsWith('@')) e.key: '${e.value}',
    };
  }

  Set<String> tokens(String text) => {
    for (final m in icu.allMatches(text)) '${m.group(1)}:${m.group(2)}',
    for (final m in simple.allMatches(text)) '${m.group(1)}:',
  };

  final es = load('es');

  for (final language in languages) {
    test('$language: todas las claves y marcadores del español', () {
      final other = load(language);
      expect(es.keys.toSet().difference(other.keys.toSet()), isEmpty);
      for (final key in es.keys) {
        expect(tokens(other[key]!), tokens(es[key]!), reason: key);
      }
    });
  }
}
