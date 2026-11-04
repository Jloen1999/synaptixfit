import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/training/live_session_draft.dart';

/// [LiveSessionDraft] por sesión en el almacenamiento del teléfono (JSON).
class LiveSessionDraftStorage {
  LiveSessionDraftStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static String _key(String sessionId) => 'live_session_draft_$sessionId';

  Future<LiveSessionDraft> load(String sessionId) async {
    final raw = await _preferences.getString(_key(sessionId));
    if (raw == null) return const LiveSessionDraft();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final since = j['timerSince'] as String?;
    final swaps = (j['swaps'] as Map<String, dynamic>?) ?? const {};
    return LiveSessionDraft(
      timerPlannedExerciseId: j['timerPlannedExerciseId'] as String?,
      timerSet: j['timerSet'] as int?,
      timerSince: since == null ? null : DateTime.parse(since).toLocal(),
      timerBanked: j['timerBanked'] as int? ?? 0,
      swaps: {
        for (final entry in swaps.entries)
          entry.key: _swap(entry.value as Map<String, dynamic>),
      },
    );
  }

  Future<void> save(String sessionId, LiveSessionDraft draft) async {
    if (draft.isEmpty) {
      await _preferences.remove(_key(sessionId));
      return;
    }
    await _preferences.setString(
      _key(sessionId),
      jsonEncode({
        'timerPlannedExerciseId': draft.timerPlannedExerciseId,
        'timerSet': draft.timerSet,
        'timerSince': draft.timerSince?.toUtc().toIso8601String(),
        'timerBanked': draft.timerBanked,
        'swaps': {
          for (final entry in draft.swaps.entries)
            entry.key: {
              'exerciseId': entry.value.exerciseId,
              'name': entry.value.name,
              'gifUrl': entry.value.gifUrl,
              'previewUrl': entry.value.previewUrl,
            },
        },
      }),
    );
  }

  static ExerciseSwap _swap(Map<String, dynamic> j) => ExerciseSwap(
    exerciseId: j['exerciseId'] as String,
    name: j['name'] as String,
    gifUrl: j['gifUrl'] as String?,
    previewUrl: j['previewUrl'] as String?,
  );
}
