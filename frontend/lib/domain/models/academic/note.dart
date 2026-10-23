import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/visibility.dart';

part 'note.freezed.dart';

/// Apunte en Markdown.
@freezed
abstract class Note with _$Note {
  const factory Note({
    required String id,
    String? subjectId,
    required String title,
    required String content,
    required Visibility visibility,
    required bool quickNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Note;
}

/// Apunte que un amigo ha compartido.
@freezed
abstract class SharedNote with _$SharedNote {
  const factory SharedNote({
    required String id,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    String? subjectId,
    required String title,
    required String content,
    required Visibility visibility,
    DateTime? updatedAt,
  }) = _SharedNote;
}

/// Página de apuntes compartidos.
@freezed
abstract class SharedNotesPage with _$SharedNotesPage {
  const factory SharedNotesPage({
    required List<SharedNote> items,
    required int page,
    required int totalPages,
  }) = _SharedNotesPage;

  const SharedNotesPage._();

  bool get hasMore => page + 1 < totalPages;
}
