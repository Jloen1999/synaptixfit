import '../../models/profile/catalog.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_catalog_repository_contract.dart';

/// Busca universidades del catálogo.
abstract interface class SearchUniversitiesUseCaseContract {
  Future<AppResult<List<University>>> call(String? query);
}

class SearchUniversitiesUseCase implements SearchUniversitiesUseCaseContract {
  const SearchUniversitiesUseCase(this._repository);

  final ProfileCatalogRepositoryContract _repository;

  @override
  Future<AppResult<List<University>>> call(String? query) =>
      _repository.searchUniversities(query);
}
