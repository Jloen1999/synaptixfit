import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/planner_enums.dart';
import '../../domain/models/planner/active_focus_timer.dart';

/// Guarda en el teléfono la fase del Pomodoro en curso (JSON en
/// SharedPreferences; en web, almacenamiento local del navegador).
class ActiveFocusTimerStorage {
  ActiveFocusTimerStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const _key = 'active_focus_timer';

  Future<ActiveFocusTimer?> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final phase = FocusPhase.values.asNameMap()[json['phase']];
    if (phase == null) return null;
    final endsAt = json['endsAt'] as String?;
    return ActiveFocusTimer(
      phase: phase,
      running: json['running'] as bool? ?? false,
      endsAt: endsAt == null ? null : DateTime.parse(endsAt),
      totalSeconds: json['totalSeconds'] as int,
      remainingSeconds: json['remainingSeconds'] as int,
      completedFocusCycles: json['completedFocusCycles'] as int? ?? 0,
      subjectId: json['subjectId'] as String?,
      blockId: json['blockId'] as String?,
      accountId: json['accountId'] as String?,
    );
  }

  Future<void> save(ActiveFocusTimer timer) => _preferences.setString(
    _key,
    jsonEncode({
      'phase': timer.phase.name,
      'running': timer.running,
      'endsAt': timer.endsAt?.toUtc().toIso8601String(),
      'totalSeconds': timer.totalSeconds,
      'remainingSeconds': timer.remainingSeconds,
      'completedFocusCycles': timer.completedFocusCycles,
      'subjectId': timer.subjectId,
      'blockId': timer.blockId,
      'accountId': timer.accountId,
    }),
  );

  Future<void> clear() => _preferences.remove(_key);
}
