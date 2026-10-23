part of 'admin_reports_bloc.dart';

@freezed
sealed class AdminReportsEvent with _$AdminReportsEvent {
  const factory AdminReportsEvent.started() = AdminReportsStarted;

  const factory AdminReportsEvent.refreshed() = AdminReportsRefreshed;

  /// Filtro por tipo; nulo muestra publicaciones y comentarios.
  const factory AdminReportsEvent.typeChanged(AdminReportType? type) =
      AdminReportsTypeChanged;

  const factory AdminReportsEvent.pageRequested(int page) =
      AdminReportsPageRequested;

  const factory AdminReportsEvent.dismissRequested(ReportedContent item) =
      AdminReportsDismissRequested;

  const factory AdminReportsEvent.removeRequested(ReportedContent item) =
      AdminReportsRemoveRequested;
}
