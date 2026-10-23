import '../../models/result/app_result.dart';
import '../../repositories/profile_catalog_repository_contract.dart';

/// Crea asignaturas del usuario desde el catálogo.
abstract interface class AddSubjectsFromCatalogUseCaseContract {
  Future<AppResult<int>> call(List<String> catalogSubjectIds);
}

class AddSubjectsFromCatalogUseCase
    implements AddSubjectsFromCatalogUseCaseContract {
  const AddSubjectsFromCatalogUseCase(this._repository);

  final ProfileCatalogRepositoryContract _repository;

  @override
  Future<AppResult<int>> call(List<String> catalogSubjectIds) =>
      _repository.addSubjectsFromCatalog(catalogSubjectIds);
}
