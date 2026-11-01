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

/// Resumen de un apunte que otro usuario comparte (sin el contenido).
///
/// [visibility] es la efectiva: la más restrictiva entre la del apunte y la
/// del perfil de su autor. La asignatura es la del plan de estudios, no la
/// asignatura privada del autor.
@freezed
abstract class SharedNoteSummary with _$SharedNoteSummary {
  const factory SharedNoteSummary({
    required String id,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    String? catalogSubjectId,
    String? catalogSubjectName,
    required String title,
    required String excerpt,
    required Visibility visibility,
    DateTime? updatedAt,

    /// Es un apunte propio (solo al ver mis apuntes compartidos).
    @Default(false) bool mine,
  }) = _SharedNoteSummary;
}

/// Apunte compartido completo, para leerlo y guardar una copia.
@freezed
abstract class SharedNote with _$SharedNote {
  const factory SharedNote({
    required String id,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    String? catalogSubjectId,
    String? catalogSubjectName,
    required String title,
    required String content,
    required Visibility visibility,
    DateTime? updatedAt,
    @Default(false) bool mine,
  }) = _SharedNote;
}

/// Página de apuntes compartidos.
@freezed
abstract class SharedNoteSummaryPage with _$SharedNoteSummaryPage {
  const factory SharedNoteSummaryPage({
    required List<SharedNoteSummary> items,
    required int page,
    required int totalPages,
  }) = _SharedNoteSummaryPage;

  const SharedNoteSummaryPage._();

  bool get hasMore => page + 1 < totalPages;
}
