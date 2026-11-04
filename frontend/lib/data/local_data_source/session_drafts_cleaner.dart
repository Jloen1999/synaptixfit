import 'package:shared_preferences/shared_preferences.dart';

/// Borra del teléfono lo que la sesión en vivo guarda por sesión
/// (`live_session_draft_*` y `pending_sets_*`). Lo usa `AuthRepository` al
/// cerrar sesión: así no se quedan para siempre ni los ve otra cuenta.
class SessionDraftsCleaner {
  SessionDraftsCleaner([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const _prefixes = ['live_session_draft_', 'pending_sets_'];

  Future<void> clear() async {
    final keys = await _preferences.getKeys();
    for (final key in keys) {
      if (_prefixes.any(key.startsWith)) await _preferences.remove(key);
    }
  }
}
