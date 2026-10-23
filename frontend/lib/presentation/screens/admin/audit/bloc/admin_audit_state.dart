part of 'admin_audit_bloc.dart';

@freezed
abstract class AdminAuditState with _$AdminAuditState {
  const factory AdminAuditState({
    @Default(AdminStatus.initial) AdminStatus status,
    @Default(AuditQuery()) AuditQuery query,
    @Default(0) int page,
    AdminPage<AuditEntry>? entries,
    AppError? error,
  }) = _AdminAuditState;
}
