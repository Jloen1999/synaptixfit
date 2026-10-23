import '../../models/profile/catalog.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Asignaturas del plan de estudios de las carreras vinculadas.
abstract interface class GetMyCatalogSubjectsUseCaseContract {
  Future<AppResult<CatalogSubjectPage>> call({
    int? course,
    int? semester,
    String? query,
    int page = 0,
  });
}

class GetMyCatalogSubjectsUseCase
    implements GetMyCatalogSubjectsUseCaseContract {
  const GetMyCatalogSubjectsUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<CatalogSubjectPage>> call({
    int? course,
    int? semester,
    String? query,
    int page = 0,
  }) => _repository.getMyCatalogSubjects(
    course: course,
    semester: semester,
    query: query,
    page: page,
  );
}
