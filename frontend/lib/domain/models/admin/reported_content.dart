import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/admin/admin_report_type.dart';

part 'reported_content.freezed.dart';

/// Publicación o comentario reportado pendiente de moderación.
@freezed
abstract class ReportedContent with _$ReportedContent {
  const factory ReportedContent({
    required AdminReportType type,
    required String id,
    String? postId,
    String? authorId,
    String? authorName,
    required String content,
    String? reportedBy,
    DateTime? createdAt,
  }) = _ReportedContent;
}
