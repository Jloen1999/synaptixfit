import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synaptixfit/data/local_data_source/session_drafts_cleaner.dart';

/// Preferencias del teléfono en memoria (solo lo que usa el limpiador).
class _MemoryPreferences extends Fake implements SharedPreferencesAsync {
  _MemoryPreferences(this.values);

  final Map<String, String> values;

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async =>
      values.keys.toSet();

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Cerrar sesión solo avisa si se perdería algo que el servidor no tiene
/// (series sin conexión, carreras en curso o por subir) y después lo borra.
void main() {
  test('sin nada guardado no hay datos sin subir', () async {
    final cleaner = SessionDraftsCleaner(_MemoryPreferences({}));
    expect(await cleaner.hasUnsent(), isFalse);
  });

  test('el cronómetro de la sesión no cuenta: se rehace solo', () async {
    final cleaner = SessionDraftsCleaner(
      _MemoryPreferences({'live_session_draft_s1': '{}', 'theme': 'dark'}),
    );
    expect(await cleaner.hasUnsent(), isFalse);
  });

  for (final key in ['pending_sets_s1', 'run_recording', 'run_pending_k1']) {
    test('$key cuenta como dato sin subir', () async {
      final cleaner = SessionDraftsCleaner(_MemoryPreferences({key: '{}'}));
      expect(await cleaner.hasUnsent(), isTrue);
    });
  }

  test('clear borra solo lo de la sesión y las carreras', () async {
    final values = {
      'live_session_draft_s1': '{}',
      'pending_sets_s1': '[]',
      'run_recording': '{}',
      'run_pending_k1': '{}',
      'theme': 'dark',
    };
    final cleaner = SessionDraftsCleaner(_MemoryPreferences(values));
    await cleaner.clear();
    expect(values.keys, ['theme']);
    expect(await cleaner.hasUnsent(), isFalse);
  });
}
