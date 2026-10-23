import '../../domain/models/profile/catalog.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/profile_catalog_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/profile/profile_catalog_remote_data_source.dart';

class ProfileCatalogRepository implements ProfileCatalogRepositoryContract {
  ProfileCatalogRepository(this._remote);

  final ProfileCatalogRemoteDataSource _remote;

  @override
  Future<AppResult<List<University>>> searchUniversities(String? query) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.universities(
          query?.trim(),
        )).map((u) => u.toDomain()).toList(),
      );

  @override
  Future<AppResult<List<Degree>>> searchDegrees(
    String universityId,
    String? query,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.degrees(
      universityId,
      query?.trim(),
    )).map((d) => d.toDomain()).toList(),
  );

  @override
  Future<AppResult<int>> addSubjectsFromCatalog(
    List<String> catalogSubjectIds,
  ) => RepositoryErrorHandler.guard(
    () => _remote.createSubjectsFromCatalog(catalogSubjectIds),
  );
}
