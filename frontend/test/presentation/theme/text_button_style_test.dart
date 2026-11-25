import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Jerarquía de botones y nodos del lector (ADR 0065), comprobados en el
/// código de `lib/presentation`:
/// - ningún botón se pinta de rojo a mano: borrar va con `AppDangerButton`
///   (borde rojo con anillo de foco) y confirmar un borrado en un diálogo con
///   `AppDangerButton.confirmStyleOf`;
/// - ningún `TextButton` quita su contorno ni se pone un tema local (la acción
///   de un `SnackBar` la pinta Flutter, no se escribe a mano);
/// - todo `Semantics(button: true, excludeSemantics: true)` lleva `onTap:`.
void main() {
  final files = Directory('lib/presentation')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.contains('gen_l10n'))
      .toList();

  /// Donde se definen los estilos comunes: el tema y el botón de borrar.
  bool styleSource(File f) =>
      f.path.endsWith('app_theme.dart') ||
      f.path.endsWith('app_danger_button.dart');

  String where(File file, String source, int offset) =>
      '${file.path}:${'\n'.allMatches(source.substring(0, offset)).length + 1}';

  test('ningún botón rojo hecho a mano', () {
    final start = RegExp(
      r'(?<![A-Za-z0-9_])(\w+\.styleFrom|OutlinedButton(\.icon)?)\(',
    );
    // `colors.error`, `colorScheme.error` o una variable `error` como color.
    final red = RegExp(r'\.error\b(?!\s*[?!]?\s*\()|[:,(]\s*error\b');
    final offenders = <String>[];
    for (final file in files.where((f) => !styleSource(f))) {
      final source = file.readAsStringSync();
      for (final match in start.allMatches(source)) {
        if (red.hasMatch(_balanced(source, match.end))) {
          offenders.add(where(file, source, match.start));
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Para borrar, descartar o bloquear usa AppDangerButton (o su '
          'styleOf); para confirmarlo en un diálogo, '
          'AppDangerButton.confirmStyleOf (ADR 0065).',
    );
  });

  test('ningún TextButton quita su contorno ni lleva un tema propio', () {
    final textButton = RegExp(r'(?<![A-Za-z0-9_])TextButton(\.icon)?\(');
    final textStyleFrom = RegExp(r'(?<![A-Za-z0-9_])TextButton\.styleFrom\(');
    final localTheme = RegExp(r'(?<![A-Za-z0-9_])TextButtonTheme\(');
    // `side: null` no toca el contorno del tema; cualquier otro valor, sí.
    final side = RegExp(r'\bside:\s*(?!null\b)');
    final offenders = <String>[];
    for (final file in files.where((f) => !styleSource(f))) {
      final source = file.readAsStringSync();
      for (final match in textButton.allMatches(source)) {
        if (_balanced(source, match.end).contains('BorderSide.none')) {
          offenders.add('${where(file, source, match.start)} (sin contorno)');
        }
      }
      for (final match in textStyleFrom.allMatches(source)) {
        if (side.hasMatch(_balanced(source, match.end))) {
          offenders.add('${where(file, source, match.start)} (side:)');
        }
      }
      for (final match in localTheme.allMatches(source)) {
        offenders.add('${where(file, source, match.start)} (tema local)');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Un TextButton es «Otra opción»: el contorno y el fondo los pone '
          'el tema (ADR 0065).',
    );
  });

  test('todo botón del lector que excluye a sus hijos lleva onTap', () {
    final semantics = RegExp(r'(?<![A-Za-z0-9_])Semantics\(');
    final offenders = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in semantics.allMatches(source)) {
        final args = _arguments(source, match.end);
        if (RegExp(r'\bbutton:\s*true').hasMatch(args) &&
            RegExp(r'\bexcludeSemantics:\s*true').hasMatch(args) &&
            !RegExp(r'\bonTap:').hasMatch(args)) {
          offenders.add(where(file, source, match.start));
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Con excludeSemantics el toque del botón de dentro no llega al '
          'lector: repite la acción en onTap: (ADR 0064 y 0065).',
    );
  });
}

/// Argumentos de la llamada que empieza en [from] (justo tras el paréntesis).
String _balanced(String source, int from) {
  var depth = 1;
  var i = from;
  while (i < source.length && depth > 0) {
    final c = source[i];
    if (c == '(') depth++;
    if (c == ')') depth--;
    i++;
  }
  return source.substring(from, i);
}

/// Argumentos con nombre de primer nivel de la llamada en [from], hasta
/// `child:` (lo de dentro del hijo no cuenta).
String _arguments(String source, int from) {
  final call = _balanced(source, from);
  var depth = 0;
  for (var i = 0; i < call.length; i++) {
    final c = call[i];
    if ('([{'.contains(c)) depth++;
    if (')]}'.contains(c)) depth--;
    if (depth == 0 && call.startsWith('child:', i)) {
      return call.substring(0, i);
    }
  }
  return call;
}
