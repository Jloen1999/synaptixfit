import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el dispositivo la apariencia elegida (valor de
/// `AppearanceMode.storageValue`).
abstract interface class AppearanceStorage {
  Future<String?> read();

  Future<void> write(String value);
}

/// [AppearanceStorage] con `shared_preferences`.
class SharedPrefsAppearanceStorage implements AppearanceStorage {
  SharedPrefsAppearanceStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'sfx_appearance_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}
