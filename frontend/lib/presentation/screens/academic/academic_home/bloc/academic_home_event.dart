part of 'academic_home_bloc.dart';

@freezed
sealed class AcademicHomeEvent with _$AcademicHomeEvent {
  const factory AcademicHomeEvent.started() = AcademicHomeStarted;

  /// Recarga sin mostrar el esqueleto (pull-to-refresh o al volver).
  const factory AcademicHomeEvent.refreshed() = AcademicHomeRefreshed;

  const factory AcademicHomeEvent.archivedToggled({required bool archived}) =
      AcademicHomeArchivedToggled;
}
