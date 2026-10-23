import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el dispositivo si el usuario activó aquí los recordatorios.
abstract interface class ReminderSettingsStorage {
  Future<bool> readEnabled();

  Future<void> writeEnabled(bool enabled);
}

/// [ReminderSettingsStorage] con `shared_preferences`. Sin valor guardado
/// cuenta como desactivado: el usuario lo activa y concede el permiso.
class SharedPrefsReminderSettingsStorage implements ReminderSettingsStorage {
  SharedPrefsReminderSettingsStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _enabledKey = 'sfx_device_reminders_enabled';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> readEnabled() async =>
      await _preferences.getBool(_enabledKey) ?? false;

  @override
  Future<void> writeEnabled(bool enabled) =>
      _preferences.setBool(_enabledKey, enabled);
}
