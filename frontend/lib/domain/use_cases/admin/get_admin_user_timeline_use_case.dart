import '../../models/admin/admin_page.dart';
import '../../models/admin/admin_user_stats.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Línea de tiempo paginada de un usuario.
abstract interface class GetAdminUserTimelineUseCaseContract {
  Future<AppResult<AdminPage<AdminTimelineEntry>>> call(
    String userId, {
    required int page,
    required int size,
  });
}

class GetAdminUserTimelineUseCase
    implements GetAdminUserTimelineUseCaseContract {
  const GetAdminUserTimelineUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminPage<AdminTimelineEntry>>> call(
    String userId, {
    required int page,
    required int size,
  }) => _repository.getUserTimeline(userId, page: page, size: size);
}
