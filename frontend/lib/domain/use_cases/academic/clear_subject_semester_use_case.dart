import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Quita el curso y semestre.
abstract interface class ClearSubjectSemesterUseCaseContract {
  Future<AppResult<Unit>> call(String subjectId);
}

class ClearSubjectSemesterUseCase
    implements ClearSubjectSemesterUseCaseContract {
  const ClearSubjectSemesterUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String subjectId) =>
      _repository.clearSemester(subjectId);
}
