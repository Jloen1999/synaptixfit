import '../../enums/admin/admin_report_type.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/admin_moderation_repository_contract.dart';

/// Descarta un reporte manteniendo el contenido.
abstract interface class DismissReportUseCaseContract {
  Future<AppResult<Unit>> call(AdminReportType type, String id);
}

class DismissReportUseCase implements DismissReportUseCaseContract {
  const DismissReportUseCase(this._repository);

  final AdminModerationRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(AdminReportType type, String id) =>
      _repository.dismissReport(type, id);
}
