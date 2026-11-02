import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el teléfono si se pidió no volver a explicar el cronómetro al
/// empezar una sesión de entrenamiento.
abstract interface class SessionClockIntroStorage {
  Future<bool> isHidden();

  Future<void> hide();
}

/// [SessionClockIntroStorage] con `shared_preferences`.
class SharedPrefsSessionClockIntroStorage implements SessionClockIntroStorage {
  SharedPrefsSessionClockIntroStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'sfx_session_clock_intro_hidden';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isHidden() async => await _preferences.getBool(_key) ?? false;

  @override
  Future<void> hide() => _preferences.setBool(_key, true);
}
