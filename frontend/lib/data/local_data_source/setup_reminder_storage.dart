import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el dispositivo hasta cuándo se pospuso el aviso de configuración
/// (milisegundos desde 1970), por usuario: otra cuenta en el mismo dispositivo
/// tiene su propio «Ahora no».
abstract interface class SetupReminderStorage {
  Future<int?> read(String userId);

  Future<void> write(String userId, int epochMillis);
}

/// [SetupReminderStorage] con `shared_preferences`.
class SharedPrefsSetupReminderStorage implements SetupReminderStorage {
  SharedPrefsSetupReminderStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static String _key(String userId) => 'sfx_setup_snoozed_until_$userId';

  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> read(String userId) => _preferences.getInt(_key(userId));

  @override
  Future<void> write(String userId, int epochMillis) =>
      _preferences.setInt(_key(userId), epochMillis);
}
