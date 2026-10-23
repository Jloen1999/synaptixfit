import '../../models/profile/catalog.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_catalog_repository_contract.dart';

/// Busca carreras de una universidad.
abstract interface class SearchDegreesUseCaseContract {
  Future<AppResult<List<Degree>>> call(String universityId, String? query);
}

class SearchDegreesUseCase implements SearchDegreesUseCaseContract {
  const SearchDegreesUseCase(this._repository);

  final ProfileCatalogRepositoryContract _repository;

  @override
  Future<AppResult<List<Degree>>> call(String universityId, String? query) =>
      _repository.searchDegrees(universityId, query);
}
