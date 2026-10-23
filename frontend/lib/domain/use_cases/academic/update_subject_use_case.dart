import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Edita una asignatura.
abstract interface class UpdateSubjectUseCaseContract {
  Future<AppResult<Subject>> call(
    String subjectId,
    SubjectInput input, {
    bool clearNextAssessment = false,
  });
}

class UpdateSubjectUseCase implements UpdateSubjectUseCaseContract {
  const UpdateSubjectUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<Subject>> call(
    String subjectId,
    SubjectInput input, {
    bool clearNextAssessment = false,
  }) => _repository.updateSubject(
    subjectId,
    input,
    clearNextAssessment: clearNextAssessment,
  );
}
