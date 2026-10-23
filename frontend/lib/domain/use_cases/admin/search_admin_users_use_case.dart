import '../../models/admin/admin_page.dart';
import '../../models/admin/admin_queries.dart';
import '../../models/admin/admin_user.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Busca usuarios con filtros, orden y paginación.
abstract interface class SearchAdminUsersUseCaseContract {
  Future<AppResult<AdminPage<AdminUserSummary>>> call({
    required AdminUserQuery query,
    required int page,
    required int size,
  });
}

class SearchAdminUsersUseCase implements SearchAdminUsersUseCaseContract {
  const SearchAdminUsersUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminPage<AdminUserSummary>>> call({
    required AdminUserQuery query,
    required int page,
    required int size,
  }) => _repository.searchUsers(query: query, page: page, size: size);
}
