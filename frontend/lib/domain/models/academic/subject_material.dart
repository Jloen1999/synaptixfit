import '../../enums/study_source_type.dart';
import 'note.dart';
import 'subject_file.dart';

/// Un elemento de la lista «Material» de una asignatura (ADR 0064): un apunte
/// o un archivo, en una sola lista. La página decide su icono y su texto.
sealed class SubjectMaterial {
  const SubjectMaterial();

  String get id;
  String get title;
  StudySourceType get sourceType;

  /// Última vez que cambió (o se subió): ordena la lista.
  DateTime? get date;

  /// La IA puede leerlo (repaso, práctica y asistente).
  bool get aiReadable;

  /// Apuntes y archivos juntos, lo más reciente primero; lo que no tiene
  /// fecha, al final, y a igual fecha, los apuntes antes.
  static List<SubjectMaterial> merge(
    List<Note> notes,
    List<SubjectFile> files,
  ) {
    final all = <SubjectMaterial>[
      for (final n in notes) NoteMaterial(n),
      for (final f in files) FileMaterial(f),
    ];
    final order = {for (var i = 0; i < all.length; i++) all[i]: i};
    all.sort((a, b) {
      final da = a.date;
      final db = b.date;
      if (da == null || db == null) {
        if (da != db) return da == null ? 1 : -1;
        return order[a]!.compareTo(order[b]!);
      }
      final byDate = db.compareTo(da);
      return byDate != 0 ? byDate : order[a]!.compareTo(order[b]!);
    });
    return all;
  }
}

/// Un apunte en la lista «Material».
final class NoteMaterial extends SubjectMaterial {
  const NoteMaterial(this.note);

  final Note note;

  @override
  String get id => note.id;
  @override
  String get title => note.title;
  @override
  StudySourceType get sourceType => StudySourceType.note;
  @override
  DateTime? get date => note.updatedAt ?? note.createdAt;
  @override
  bool get aiReadable => true;

  @override
  bool operator ==(Object other) => other is NoteMaterial && other.note == note;
  @override
  int get hashCode => note.hashCode;
}

/// Un archivo subido en la lista «Material».
final class FileMaterial extends SubjectMaterial {
  const FileMaterial(this.file);

  final SubjectFile file;

  @override
  String get id => file.id;
  @override
  String get title => file.fileName;
  @override
  StudySourceType get sourceType => StudySourceType.file;
  @override
  DateTime? get date => file.createdAt;
  @override
  bool get aiReadable => file.aiReadable;

  @override
  bool operator ==(Object other) => other is FileMaterial && other.file == file;
  @override
  int get hashCode => file.hashCode;
}
