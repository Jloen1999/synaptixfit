import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Borra una asignatura.
abstract interface class DeleteSubjectUseCaseContract {
  Future<AppResult<Unit>> call(String subjectId);
}

class DeleteSubjectUseCase implements DeleteSubjectUseCaseContract {
  const DeleteSubjectUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String subjectId) =>
      _repository.deleteSubject(subjectId);
}
