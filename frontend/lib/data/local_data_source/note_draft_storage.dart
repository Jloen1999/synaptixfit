import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/visibility.dart';
import '../../domain/models/academic/note_draft.dart';

/// Guarda en el teléfono los borradores de apuntes (JSON en SharedPreferences;
/// en web, almacenamiento local del navegador). Una clave por cuenta y apunte.
class NoteDraftStorage {
  NoteDraftStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static String _key(String accountId, String? noteId) =>
      'note_draft:$accountId:${noteId ?? 'new'}';

  Future<NoteDraft?> load({required String accountId, String? noteId}) async {
    final raw = await _preferences.getString(_key(accountId, noteId));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return NoteDraft(
      accountId: accountId,
      noteId: noteId,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      visibility: Visibility.fromApi(json['visibility'] as String?),
      quickNote: json['quickNote'] as bool? ?? false,
      subjectId: json['subjectId'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String).toLocal(),
    );
  }

  Future<void> save(NoteDraft draft) => _preferences.setString(
    _key(draft.accountId, draft.noteId),
    jsonEncode({
      'title': draft.title,
      'content': draft.content,
      'visibility': draft.visibility.apiValue,
      'quickNote': draft.quickNote,
      'subjectId': draft.subjectId,
      'savedAt': draft.savedAt.toUtc().toIso8601String(),
    }),
  );

  Future<void> discard({required String accountId, String? noteId}) =>
      _preferences.remove(_key(accountId, noteId));
}
