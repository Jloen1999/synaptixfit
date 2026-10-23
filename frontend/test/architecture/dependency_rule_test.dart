import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Imports prohibidos por carpeta (regla de dependencia del núcleo).
const _rules = <String, List<String>>{
  'lib/domain': [
    '/data/',
    '/presentation/',
    '/app/',
    'package:flutter/',
    'package:dio/',
    'package:http/',
    'package:flutter_bloc/',
    'package:google_sign_in',
    'package:flutter_secure_storage',
    'package:shared_preferences',
    'package:flutter_local_notifications',
    'package:timezone',
  ],
  'lib/data': ['/presentation/'],
  'lib/presentation': [
    '/data/',
    'package:dio/',
    'package:google_sign_in/',
    'package:flutter_local_notifications',
    'package:timezone',
    'package:shared_preferences',
  ],
};

void main() {
  for (final rule in _rules.entries) {
    test('${rule.key} respeta la regla de dependencia', () {
      final violations = <String>[];
      final files = Directory(rule.key)
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.endsWith('.freezed.dart'),
          );

      for (final file in files) {
        final imports = file.readAsLinesSync().where(
          (l) => l.trimLeft().startsWith('import '),
        );
        for (final line in imports) {
          for (final banned in rule.value) {
            if (line.contains(banned)) violations.add('${file.path} → $line');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  }
}
