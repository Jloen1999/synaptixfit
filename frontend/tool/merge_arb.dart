// Une los fragmentos de traducción de cada módulo en lib/presentation/l10n/app_<idioma>.arb.
//
//   dart run tool/merge_arb.dart && flutter gen-l10n
//
// Cada módulo mantiene su fragmento en lib/presentation/l10n/parts/app_<idioma>_<modulo>.arb, así
// varios equipos pueden añadir textos sin pisarse. El español (app_es_*) es la plantilla: lleva los
// metadatos (@clave) y manda sobre qué claves existen. Los demás idiomas solo traen el texto; una
// clave que no esté en español, o duplicada entre fragmentos, es error. Una clave sin traducir usa
// el texto en español (flutter gen-l10n lo avisa) y el test de traducciones la señala.
import 'dart:convert';
import 'dart:io';

const _dir = 'lib/presentation/l10n';
const _template = 'es';

void main() {
  final byLanguage = <String, List<File>>{};
  final name = RegExp(r'app_([a-z]{2})_[a-z_]+\.arb$');
  for (final file in Directory('$_dir/parts').listSync().whereType<File>()) {
    final match = name.firstMatch(file.uri.pathSegments.last);
    if (match == null) continue;
    (byLanguage[match.group(1)!] ??= []).add(file);
  }

  var failed = false;
  Set<String>? templateKeys;
  for (final language in [
    _template,
    ...byLanguage.keys.where((l) => l != _template).toList()..sort(),
  ]) {
    final parts = (byLanguage[language] ?? [])
      ..sort((a, b) => a.path.compareTo(b.path));
    final merged = <String, dynamic>{'@@locale': language};
    final owners = <String, String>{};
    for (final file in parts) {
      final content =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in content.entries) {
        if (entry.key == '@@locale') continue;
        // Los metadatos solo viven en la plantilla.
        if (language != _template && entry.key.startsWith('@')) continue;
        final owner = owners[entry.key];
        if (owner != null) {
          stderr.writeln(
            'Clave duplicada "${entry.key}" en ${file.path} (ya definida en $owner)',
          );
          failed = true;
          continue;
        }
        if (templateKeys != null && !templateKeys.contains(entry.key)) {
          stderr.writeln(
            'Clave "${entry.key}" de ${file.path} no existe en español',
          );
          failed = true;
          continue;
        }
        owners[entry.key] = file.path;
        merged[entry.key] = entry.value;
      }
    }
    if (language == _template) {
      templateKeys = owners.keys.where((k) => !k.startsWith('@')).toSet();
    }
    File('$_dir/app_$language.arb').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(merged)}\n',
    );
    final total = owners.keys.where((k) => !k.startsWith('@')).length;
    stdout.writeln(
      'app_$language.arb generado con $total claves de ${parts.length} fragmentos',
    );
  }

  if (failed) exit(1);
}
