import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Asigna curso y semestre.
abstract interface class AssignSubjectSemesterUseCaseContract {
  Future<AppResult<SubjectSemester>> call(
    String subjectId, {
    required int course,
    required int semester,
  });
}

class AssignSubjectSemesterUseCase
    implements AssignSubjectSemesterUseCaseContract {
  const AssignSubjectSemesterUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<SubjectSemester>> call(
    String subjectId, {
    required int course,
    required int semester,
  }) =>
      _repository.assignSemester(subjectId, course: course, semester: semester);
}
