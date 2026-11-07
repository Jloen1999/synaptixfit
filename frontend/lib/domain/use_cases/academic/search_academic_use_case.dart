import '../../models/academic/academic_search.dart';
import '../../models/result/app_result.dart';
import '../../repositories/academic_search_repository_contract.dart';

/// Busca a la vez asignaturas, apuntes, archivos y entregas o exámenes en el
/// servidor (las listas de apuntes van paginadas: filtrar aquí no basta).
abstract interface class SearchAcademicUseCaseContract {
  /// Texto mínimo para buscar: con menos, el servidor lo rechaza.
  static const minLength = 2;

  Future<AppResult<AcademicSearchResult>> call(String query);
}

class SearchAcademicUseCase implements SearchAcademicUseCaseContract {
  const SearchAcademicUseCase(this._repository);

  final AcademicSearchRepositoryContract _repository;

  @override
  Future<AppResult<AcademicSearchResult>> call(String query) =>
      _repository.search(query.trim());
}
