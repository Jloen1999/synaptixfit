import '../../enums/admin/admin_report_type.dart';
import '../../models/admin/admin_page.dart';
import '../../models/admin/reported_content.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_moderation_repository_contract.dart';

/// Cola de contenido reportado.
abstract interface class GetReportedContentUseCaseContract {
  Future<AppResult<AdminPage<ReportedContent>>> call({
    AdminReportType? type,
    required int page,
    required int size,
  });
}

class GetReportedContentUseCase implements GetReportedContentUseCaseContract {
  const GetReportedContentUseCase(this._repository);

  final AdminModerationRepositoryContract _repository;

  @override
  Future<AppResult<AdminPage<ReportedContent>>> call({
    AdminReportType? type,
    required int page,
    required int size,
  }) => _repository.getReports(type: type, page: page, size: size);
}
