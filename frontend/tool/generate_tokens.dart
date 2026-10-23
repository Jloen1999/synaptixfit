// Genera lib/presentation/theme/tokens.g.dart a partir de docs/05-design/tokens.json.
//
//   dart run tool/generate_tokens.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final source = File('../docs/05-design/tokens.json');
  final json = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final out = StringBuffer()
    ..writeln(
      '// GENERADO por tool/generate_tokens.dart desde docs/05-design/tokens.json.',
    )
    ..writeln('// No editar a mano.')
    ..writeln('// ignore_for_file: public_member_api_docs')
    ..writeln()
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln();

  final colors = json['color'] as Map<String, dynamic>;
  for (final mode in ['light', 'dark']) {
    final className =
        'Tokens${mode[0].toUpperCase()}${mode.substring(1)}Colors';
    out.writeln('abstract final class $className {');
    (colors[mode] as Map<String, dynamic>).forEach((name, token) {
      final hex = ((token as Map<String, dynamic>)[r'$value'] as String)
          .substring(1);
      out.writeln('  static const Color $name = Color(0xFF$hex);');
    });
    out
      ..writeln('}')
      ..writeln();
  }

  void dimensions(String group, String className) {
    out.writeln('abstract final class $className {');
    (json[group] as Map<String, dynamic>).forEach((name, token) {
      final value = ((token as Map<String, dynamic>)[r'$value'] as String)
          .replaceAll('px', '');
      out.writeln('  static const double $name = $value;');
    });
    out
      ..writeln('}')
      ..writeln();
  }

  dimensions('spacing', 'TokensSpacing');
  dimensions('radius', 'TokensRadius');
  dimensions('layout', 'TokensLayout');
  dimensions('size', 'TokensSize');

  out.writeln('abstract final class TokensFont {');
  (json['font'] as Map<String, dynamic>).forEach((name, token) {
    out.writeln(
      "  static const String $name = '${(token as Map<String, dynamic>)[r'$value']}';",
    );
  });
  out
    ..writeln('}')
    ..writeln()
    ..writeln('abstract final class TokensDuration {');
  (json['duration'] as Map<String, dynamic>).forEach((name, token) {
    final ms = ((token as Map<String, dynamic>)[r'$value'] as String)
        .replaceAll('ms', '');
    out.writeln('  static const Duration $name = Duration(milliseconds: $ms);');
  });
  out.writeln('}');

  File('lib/presentation/theme/tokens.g.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(out.toString());
  stdout.writeln('tokens.g.dart generado');
}
