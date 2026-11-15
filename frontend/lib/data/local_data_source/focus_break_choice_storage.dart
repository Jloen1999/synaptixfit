import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/planner/focus.dart';

/// [FocusBreakChoice] en el almacenamiento del teléfono (JSON). Es una
/// comodidad del dispositivo, como la apariencia: no viaja al servidor.
class FocusBreakChoiceStorage {
  FocusBreakChoiceStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const _key = 'focus_break_choice';

  Future<FocusBreakChoice> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const FocusBreakChoice();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return FocusBreakChoice(
      shortBreakMinutes: j['shortBreakMinutes'] as int?,
      longBreakMinutes: j['longBreakMinutes'] as int?,
    );
  }

  Future<void> save(FocusBreakChoice choice) async {
    if (choice.shortBreakMinutes == null && choice.longBreakMinutes == null) {
      await _preferences.remove(_key);
      return;
    }
    await _preferences.setString(
      _key,
      jsonEncode({
        'shortBreakMinutes': choice.shortBreakMinutes,
        'longBreakMinutes': choice.longBreakMinutes,
      }),
    );
  }
}
