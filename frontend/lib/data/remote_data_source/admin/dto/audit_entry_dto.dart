import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/admin/admin_audit_action.dart';
import '../../../../domain/enums/admin/admin_audit_entity.dart';
import '../../../../domain/enums/admin/admin_report_type.dart';
import '../../../../domain/models/admin/audit_entry.dart';
import '../../../../domain/models/admin/reported_content.dart';
import 'admin_json.dart';

part 'audit_entry_dto.freezed.dart';
part 'audit_entry_dto.g.dart';

@freezed
abstract class AuditEntryDto with _$AuditEntryDto {
  const factory AuditEntryDto({
    required String id,
    String? adminId,
    String? adminName,
    String? adminEmail,
    String? action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
    required String createdAt,
  }) = _AuditEntryDto;

  const AuditEntryDto._();

  factory AuditEntryDto.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryDtoFromJson(json);

  AuditEntry toDomain() => AuditEntry(
    id: id,
    adminId: adminId,
    adminName: adminName,
    adminEmail: adminEmail,
    action: AdminAuditAction.fromApi(action),
    entityType: AdminAuditEntity.fromApi(entityType),
    entityId: entityId,
    details: details ?? const <String, Object?>{},
    createdAt: AdminJson.instant(createdAt)!,
  );
}

@freezed
abstract class ReportedContentDto with _$ReportedContentDto {
  const factory ReportedContentDto({
    String? type,
    required String id,
    String? postId,
    String? authorId,
    String? authorName,
    @Default('') String content,
    String? reportedBy,
    String? createdAt,
  }) = _ReportedContentDto;

  const ReportedContentDto._();

  factory ReportedContentDto.fromJson(Map<String, dynamic> json) =>
      _$ReportedContentDtoFromJson(json);

  ReportedContent toDomain() => ReportedContent(
    type: AdminReportType.fromApi(type),
    id: id,
    postId: postId,
    authorId: authorId,
    authorName: authorName,
    content: content,
    reportedBy: reportedBy,
    createdAt: AdminJson.instant(createdAt),
  );
}
