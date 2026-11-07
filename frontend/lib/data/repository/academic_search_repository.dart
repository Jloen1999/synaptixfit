import '../../domain/models/academic/academic_search.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/academic_search_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/academic/academic_search_remote_data_source.dart';

/// Implementa [AcademicSearchRepositoryContract] con
/// [AcademicSearchRemoteDataSource].
class AcademicSearchRepository implements AcademicSearchRepositoryContract {
  AcademicSearchRepository(this._remote);

  final AcademicSearchRemoteDataSource _remote;

  @override
  Future<AppResult<AcademicSearchResult>> search(String query) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.search(query)).toDomain(),
      );
}
