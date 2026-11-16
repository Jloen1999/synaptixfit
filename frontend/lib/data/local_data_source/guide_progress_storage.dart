import 'package:shared_preferences/shared_preferences.dart';

/// Guías vistas en el teléfono, por cuenta (ADR 0049): otra cuenta en el mismo
/// teléfono tiene sus propias guías. Se guardan los nombres de [GuideId].
abstract interface class GuideProgressStorage {
  Future<List<String>> read(String accountId);

  Future<void> write(String accountId, List<String> guides);

  Future<void> clear(String accountId);
}

/// [GuideProgressStorage] con `shared_preferences`.
class SharedPrefsGuideProgressStorage implements GuideProgressStorage {
  SharedPrefsGuideProgressStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static String _key(String accountId) => 'sfx_guides_seen_$accountId';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>> read(String accountId) async =>
      await _preferences.getStringList(_key(accountId)) ?? const [];

  @override
  Future<void> write(String accountId, List<String> guides) =>
      _preferences.setStringList(_key(accountId), guides);

  @override
  Future<void> clear(String accountId) => _preferences.remove(_key(accountId));
}
