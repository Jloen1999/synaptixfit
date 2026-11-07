import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/training/run.dart';
import '../../domain/models/training/sport_activity.dart';

/// Carrera en curso (`run_recording`) y cola de carreras por subir
/// (`run_pending_<clave>`) en el teléfono, en JSON. Sobreviven a cerrar la app
/// y a reiniciar el móvil; `SessionDraftsCleaner` las borra al cerrar sesión
/// porque llevan la ubicación exacta (ADR 0037).
class RunRecordingStorage {
  RunRecordingStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const currentKey = 'run_recording';
  static const pendingPrefix = 'run_pending_';

  Future<RunRecording?> loadCurrent() async {
    final raw = await _preferences.getString(currentKey);
    return raw == null ? null : decode(raw);
  }

  Future<void> saveCurrent(RunRecording? recording) => recording == null
      ? _preferences.remove(currentKey)
      : _preferences.setString(currentKey, encode(recording));

  Future<List<RunRecording>> pending() async {
    final keys = await _preferences.getKeys();
    final runs = <RunRecording>[];
    for (final key in keys.where((k) => k.startsWith(pendingPrefix))) {
      final raw = await _preferences.getString(key);
      if (raw != null) runs.add(decode(raw));
    }
    runs.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return runs;
  }

  Future<void> addPending(RunRecording recording) => _preferences.setString(
    '$pendingPrefix${recording.clientKey}',
    encode(recording),
  );

  Future<void> removePending(String clientKey) =>
      _preferences.remove('$pendingPrefix$clientKey');

  static String encode(RunRecording r) => jsonEncode({
    'clientKey': r.clientKey,
    'kind': r.kind.api,
    'startedAt': r.startedAt.toUtc().toIso8601String(),
    'segment': r.segment,
    'pausedAt': r.pausedAt?.toUtc().toIso8601String(),
    'pausedSeconds': r.pausedSeconds,
    'workoutId': r.workoutId,
    'plannedBlockId': r.plannedBlockId,
    'effort': r.effort,
    'points': [
      for (final p in r.points)
        [
          p.latitude,
          p.longitude,
          p.altitude,
          p.accuracy,
          p.offsetSeconds,
          p.segment,
        ],
    ],
  });

  static RunRecording decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final paused = j['pausedAt'] as String?;
    return RunRecording(
      clientKey: j['clientKey'] as String,
      kind: ActivityKind.fromApi(j['kind'] as String?) ?? ActivityKind.run,
      startedAt: DateTime.parse(j['startedAt'] as String).toLocal(),
      segment: j['segment'] as int? ?? 0,
      pausedAt: paused == null ? null : DateTime.parse(paused).toLocal(),
      pausedSeconds: j['pausedSeconds'] as int? ?? 0,
      workoutId: j['workoutId'] as String?,
      plannedBlockId: j['plannedBlockId'] as String?,
      effort: j['effort'] as int?,
      points: [
        for (final p in (j['points'] as List<dynamic>? ?? const []))
          RunTrackPoint(
            latitude: ((p as List<dynamic>)[0] as num).toDouble(),
            longitude: (p[1] as num).toDouble(),
            altitude: (p[2] as num?)?.toDouble(),
            accuracy: (p[3] as num).toDouble(),
            offsetSeconds: (p[4] as num).toDouble(),
            segment: (p[5] as num).toInt(),
          ),
      ],
    );
  }
}
