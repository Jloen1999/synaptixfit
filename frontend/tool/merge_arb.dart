// Une los fragmentos de traducción de cada módulo en lib/presentation/l10n/app_es.arb.
//
//   dart run tool/merge_arb.dart && flutter gen-l10n
//
// Cada módulo mantiene su fragmento en lib/presentation/l10n/parts/app_es_<modulo>.arb, así
// varios equipos pueden añadir textos sin pisarse. Una clave duplicada entre fragmentos es error.
import 'dart:convert';
import 'dart:io';

void main() {
  final parts =
      Directory('lib/presentation/l10n/parts')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final merged = <String, dynamic>{'@@locale': 'es'};
  final owners = <String, String>{};
  var failed = false;

  for (final file in parts) {
    final content = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    for (final entry in content.entries) {
      if (entry.key == '@@locale') continue;
      final owner = owners[entry.key];
      if (owner != null) {
        stderr.writeln(
          'Clave duplicada "${entry.key}" en ${file.path} (ya definida en $owner)',
        );
        failed = true;
        continue;
      }
      owners[entry.key] = file.path;
      merged[entry.key] = entry.value;
    }
  }

  if (failed) exit(1);

  File('lib/presentation/l10n/app_es.arb').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(merged)}\n',
  );
  stdout.writeln(
    'app_es.arb generado con ${owners.length} claves de ${parts.length} fragmentos',
  );
}
