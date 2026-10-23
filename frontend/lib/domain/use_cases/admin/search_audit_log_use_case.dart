import '../../models/admin/admin_page.dart';
import '../../models/admin/admin_queries.dart';
import '../../models/admin/audit_entry.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_repository_contract.dart';

/// Registro de auditoría filtrado y paginado.
abstract interface class SearchAuditLogUseCaseContract {
  Future<AppResult<AdminPage<AuditEntry>>> call({
    required AuditQuery query,
    required int page,
    required int size,
  });
}

class SearchAuditLogUseCase implements SearchAuditLogUseCaseContract {
  const SearchAuditLogUseCase(this._repository);

  final AdminRepositoryContract _repository;

  @override
  Future<AppResult<AdminPage<AuditEntry>>> call({
    required AuditQuery query,
    required int page,
    required int size,
  }) => _repository.searchAudit(query: query, page: page, size: size);
}
