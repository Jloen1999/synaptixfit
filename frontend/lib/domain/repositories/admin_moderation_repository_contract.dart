import '../enums/admin/admin_report_type.dart';
import '../models/admin/admin_page.dart';
import '../models/admin/reported_content.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Moderación del contenido social reportado (`/api/v1/admin/social/**`).
abstract interface class AdminModerationRepositoryContract {
  /// Cola de reportes; [type] nulo devuelve publicaciones y comentarios.
  Future<AppResult<AdminPage<ReportedContent>>> getReports({
    AdminReportType? type,
    required int page,
    required int size,
  });

  /// Descarta el reporte y deja el contenido publicado.
  Future<AppResult<Unit>> dismissReport(AdminReportType type, String id);

  /// Borra el contenido reportado.
  Future<AppResult<Unit>> removeContent(AdminReportType type, String id);
}
