part of 'admin_audit_bloc.dart';

@freezed
sealed class AdminAuditEvent with _$AdminAuditEvent {
  const factory AdminAuditEvent.started() = AdminAuditStarted;

  const factory AdminAuditEvent.refreshed() = AdminAuditRefreshed;

  const factory AdminAuditEvent.queryChanged(AuditQuery query) =
      AdminAuditQueryChanged;

  const factory AdminAuditEvent.pageRequested(int page) =
      AdminAuditPageRequested;
}
