import '../../enums/admin/admin_report_type.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/admin_moderation_repository_contract.dart';

/// Borra una publicación o comentario reportado.
abstract interface class RemoveReportedContentUseCaseContract {
  Future<AppResult<Unit>> call(AdminReportType type, String id);
}

class RemoveReportedContentUseCase
    implements RemoveReportedContentUseCaseContract {
  const RemoveReportedContentUseCase(this._repository);

  final AdminModerationRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(AdminReportType type, String id) =>
      _repository.removeContent(type, id);
}
