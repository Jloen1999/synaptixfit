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

  // En francés y en el portugués genérico la regla de plural mete el 0 en
  // «one»: un =1{1 entraînement} sin el número se pintaría con 0 («1
  // entraînement» con 0 entrenos). Esas ramas llevan su =0 propio.
  String branch(String text, int open) {
    var depth = 0;
    for (var i = open; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}' && --depth == 0) return text.substring(open, i + 1);
    }
    return text.substring(open);
  }

  for (final language in ['fr', 'pt']) {
    test('$language: con 0 nunca sale el texto de 1', () {
      for (final MapEntry(:key, :value) in load(language).entries) {
        for (final m in icu.allMatches(value)) {
          if (m.group(2) != 'plural') continue;
          final plural = branch(value, m.start);
          final one = plural.indexOf('=1{');
          if (one < 0) continue;
          final oneText = branch(plural, one + 2);
          if (oneText.contains('{${m.group(1)}}')) continue;
          expect(
            plural.contains('=0{') || plural.contains('zero{'),
            isTrue,
            reason: key,
          );
        }
      }
    });
  }
}
