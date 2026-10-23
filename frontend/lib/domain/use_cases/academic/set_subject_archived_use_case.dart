import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Archiva o restaura una asignatura.
abstract interface class SetSubjectArchivedUseCaseContract {
  Future<AppResult<Subject>> call(String subjectId, bool archived);
}

class SetSubjectArchivedUseCase implements SetSubjectArchivedUseCaseContract {
  const SetSubjectArchivedUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Subject>> call(String subjectId, bool archived) =>
      _repository.setArchived(subjectId, archived);
}
