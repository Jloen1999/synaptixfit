import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Curso y semestre de una asignatura o `null` si no tiene.
abstract interface class GetSubjectSemesterUseCaseContract {
  Future<AppResult<SubjectSemester?>> call(String subjectId);
}

class GetSubjectSemesterUseCase implements GetSubjectSemesterUseCaseContract {
  const GetSubjectSemesterUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<SubjectSemester?>> call(String subjectId) async =>
      (await _repository.getSemesters()).map(
        (all) => all.where((s) => s.subjectId == subjectId).firstOrNull,
      );
}
