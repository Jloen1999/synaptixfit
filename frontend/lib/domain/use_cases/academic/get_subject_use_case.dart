import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Detalle de una asignatura.
abstract interface class GetSubjectUseCaseContract {
  Future<AppResult<Subject>> call(String subjectId);
}

class GetSubjectUseCase implements GetSubjectUseCaseContract {
  const GetSubjectUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Subject>> call(String subjectId) =>
      _repository.getSubject(subjectId);
}
