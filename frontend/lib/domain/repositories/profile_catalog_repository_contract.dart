import '../models/profile/catalog.dart';
import '../models/result/app_result.dart';

/// Catálogo académico público (universidades y carreras) y alta de asignaturas desde él.
abstract interface class ProfileCatalogRepositoryContract {
  Future<AppResult<List<University>>> searchUniversities(String? query);

  Future<AppResult<List<Degree>>> searchDegrees(
    String universityId,
    String? query,
  );

  /// Crea las asignaturas del usuario a partir del catálogo. Devuelve cuántas se crearon.
  Future<AppResult<int>> addSubjectsFromCatalog(List<String> catalogSubjectIds);
}
