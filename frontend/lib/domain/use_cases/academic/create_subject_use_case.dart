import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Alta manual de una asignatura.
abstract interface class CreateSubjectUseCaseContract {
  Future<AppResult<Subject>> call(SubjectInput input);
}

class CreateSubjectUseCase implements CreateSubjectUseCaseContract {
  const CreateSubjectUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Subject>> call(SubjectInput input) =>
      _repository.createSubject(input);
}
