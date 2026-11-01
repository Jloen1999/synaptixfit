import '../../enums/visibility.dart';

/// Borrador de un apunte guardado en el teléfono mientras se escribe: si la
/// app se cierra sin guardar, al volver se ofrece recuperarlo. Uno por cuenta
/// y apunte ([noteId] nulo = apunte nuevo).
class NoteDraft {
  const NoteDraft({
    required this.accountId,
    this.noteId,
    required this.title,
    required this.content,
    required this.visibility,
    required this.quickNote,
    this.subjectId,
    required this.savedAt,
  });

  /// Cuenta que lo escribió: otra cuenta en el mismo teléfono no lo ve.
  final String accountId;
  final String? noteId;
  final String title;
  final String content;
  final Visibility visibility;
  final bool quickNote;
  final String? subjectId;

  /// Cuándo se guardó por última vez (se enseña al ofrecerlo).
  final DateTime savedAt;

  /// Sin título ni texto no hay nada que recuperar.
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;
}
