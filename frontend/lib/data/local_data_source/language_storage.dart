import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el dispositivo el idioma elegido (valor de
/// `AppLanguage.storageValue`).
abstract interface class LanguageStorage {
  Future<String?> read();

  Future<void> write(String value);
}

/// [LanguageStorage] con `shared_preferences`.
class SharedPrefsLanguageStorage implements LanguageStorage {
  SharedPrefsLanguageStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'sfx_language';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}
