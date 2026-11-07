import '../models/academic/academic_search.dart';
import '../models/result/app_result.dart';

/// Buscador único de Académico: asignaturas, apuntes, archivos y entregas.
abstract interface class AcademicSearchRepositoryContract {
  Future<AppResult<AcademicSearchResult>> search(String query);
}
