part of 'academic_home_bloc.dart';

@freezed
abstract class AcademicHomeState with _$AcademicHomeState {
  const factory AcademicHomeState({
    @Default(true) bool loading,
    AppError? error,
    @Default(<Subject>[]) List<Subject> subjects,
    @Default(<StudyMaterial>[]) List<StudyMaterial> due,
    @Default(false) bool showArchived,

    /// Bandeja: apuntes sin asignatura (notas rápidas por ordenar).
    @Default(<Note>[]) List<Note> inbox,

    /// Notas que se están moviendo a una asignatura.
    @Default(<String>{}) Set<String> movingNoteIds,

    /// Resultado de mover una nota (efecto de un solo uso).
    AcademicHomeNotice? notice,
  }) = _AcademicHomeState;
}

/// Aviso puntual de la pestaña tras mover una nota.
@freezed
sealed class AcademicHomeNotice with _$AcademicHomeNotice {
  /// Nota llevada a [subjectName] ([subjectId] para el botón «Ver»).
  const factory AcademicHomeNotice.noteMoved(
    String subjectName,
    String subjectId,
  ) = AcademicHomeNoticeNoteMoved;

  const factory AcademicHomeNotice.failed(AppError error) =
      AcademicHomeNoticeFailed;
}
