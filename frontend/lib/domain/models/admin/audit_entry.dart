import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/admin/admin_audit_action.dart';
import '../../enums/admin/admin_audit_entity.dart';

part 'audit_entry.freezed.dart';

/// Registro de auditoría de una acción de administración.
@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required String id,
    String? adminId,
    String? adminName,
    String? adminEmail,
    required AdminAuditAction action,
    required AdminAuditEntity entityType,
    String? entityId,
    @Default(<String, Object?>{}) Map<String, Object?> details,
    required DateTime createdAt,
  }) = _AuditEntry;
}
