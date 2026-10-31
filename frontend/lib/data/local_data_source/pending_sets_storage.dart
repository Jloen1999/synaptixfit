import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/training/session.dart';

/// Series pendientes por sesión en el almacenamiento del teléfono (JSON). Una
/// clave por sesión: al terminarla se borra.
class PendingSetsStorage {
  PendingSetsStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static String _key(String sessionId) => 'pending_sets_$sessionId';

  Future<List<SetRecord>> load(String sessionId) async {
    final raw = await _preferences.getString(_key(sessionId));
    if (raw == null) return const [];
    return [
      for (final item in jsonDecode(raw) as List<dynamic>)
        _fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> save(String sessionId, List<SetRecord> sets) async {
    if (sets.isEmpty) {
      await _preferences.remove(_key(sessionId));
      return;
    }
    await _preferences.setString(
      _key(sessionId),
      jsonEncode([for (final s in sets) _toJson(s)]),
    );
  }

  static Map<String, dynamic> _toJson(SetRecord s) => {
    'plannedExerciseId': s.plannedExerciseId,
    'setNumber': s.setNumber,
    'repsDone': s.repsDone,
    'weightKg': s.weightKg,
    'completed': s.completed,
    'failedReps': s.failedReps,
  };

  static SetRecord _fromJson(Map<String, dynamic> j) => SetRecord(
    plannedExerciseId: j['plannedExerciseId'] as String?,
    setNumber: j['setNumber'] as int,
    repsDone: j['repsDone'] as int?,
    weightKg: (j['weightKg'] as num?)?.toDouble(),
    completed: j['completed'] as bool? ?? true,
    failedReps: j['failedReps'] as int? ?? 0,
  );
}
