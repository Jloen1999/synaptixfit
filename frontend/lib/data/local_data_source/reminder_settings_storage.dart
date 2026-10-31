import 'package:shared_preferences/shared_preferences.dart';

/// Guarda en el dispositivo si el usuario activó aquí los recordatorios.
abstract interface class ReminderSettingsStorage {
  Future<bool> readEnabled();

  Future<void> writeEnabled(bool enabled);

  /// Si ya se ofrecieron los recordatorios en este dispositivo.
  Future<bool> readOffered();

  Future<void> writeOffered();
}

/// [ReminderSettingsStorage] con `shared_preferences`. Sin valor guardado
/// cuenta como desactivado: el usuario lo activa y concede el permiso.
class SharedPrefsReminderSettingsStorage implements ReminderSettingsStorage {
  SharedPrefsReminderSettingsStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _enabledKey = 'sfx_device_reminders_enabled';
  static const _offeredKey = 'sfx_device_reminders_offered';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> readEnabled() async =>
      await _preferences.getBool(_enabledKey) ?? false;

  @override
  Future<void> writeEnabled(bool enabled) =>
      _preferences.setBool(_enabledKey, enabled);

  @override
  Future<bool> readOffered() async =>
      await _preferences.getBool(_offeredKey) ?? false;

  @override
  Future<void> writeOffered() => _preferences.setBool(_offeredKey, true);
}
