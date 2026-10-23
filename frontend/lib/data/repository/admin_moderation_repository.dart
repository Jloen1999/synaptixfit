import '../../domain/enums/admin/admin_report_type.dart';
import '../../domain/models/admin/admin_page.dart';
import '../../domain/models/admin/reported_content.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/admin_moderation_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/admin/admin_moderation_remote_data_source.dart';

class AdminModerationRepository implements AdminModerationRepositoryContract {
  AdminModerationRepository(this._remote);

  final AdminModerationRemoteDataSource _remote;

  @override
  Future<AppResult<AdminPage<ReportedContent>>> getReports({
    AdminReportType? type,
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(() async {
    final result = await _remote.reports(
      type: type?.apiValue,
      page: page,
      size: size,
    );
    return AdminPage<ReportedContent>(
      items: [for (final dto in result.items) dto.toDomain()],
      page: result.page,
      size: result.size,
      totalItems: result.totalItems,
      totalPages: result.totalPages,
    );
  });

  @override
  Future<AppResult<Unit>> dismissReport(AdminReportType type, String id) =>
      RepositoryErrorHandler.guard(() async {
        await switch (type) {
          AdminReportType.post => _remote.dismissPostReport(id),
          AdminReportType.comment => _remote.dismissCommentReport(id),
        };
        return unit;
      });

  @override
  Future<AppResult<Unit>> removeContent(AdminReportType type, String id) =>
      RepositoryErrorHandler.guard(() async {
        await switch (type) {
          AdminReportType.post => _remote.removePost(id),
          AdminReportType.comment => _remote.removeComment(id),
        };
        return unit;
      });
}
