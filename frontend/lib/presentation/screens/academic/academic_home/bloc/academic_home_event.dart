part of 'academic_home_bloc.dart';

@freezed
sealed class AcademicHomeEvent with _$AcademicHomeEvent {
  const factory AcademicHomeEvent.started() = AcademicHomeStarted;

  /// Recarga sin mostrar el esqueleto (pull-to-refresh o al volver).
  const factory AcademicHomeEvent.refreshed() = AcademicHomeRefreshed;

  const factory AcademicHomeEvent.archivedToggled({required bool archived}) =
      AcademicHomeArchivedToggled;

  /// «Mover a asignatura» de una nota de la bandeja.
  const factory AcademicHomeEvent.noteMoved({
    required String noteId,
    required String subjectId,
  }) = AcademicHomeNoteMoved;

  /// La página ya ha avisado del resultado de mover una nota.
  const factory AcademicHomeEvent.noticeHandled() = AcademicHomeNoticeHandled;
}
