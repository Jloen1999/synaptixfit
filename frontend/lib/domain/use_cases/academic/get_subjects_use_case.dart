import '../../models/academic/subject.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_repository_contract.dart';

/// Asignaturas activas o archivadas.
abstract interface class GetSubjectsUseCaseContract {
  Future<AppResult<List<Subject>>> call({required bool archived});
}

class GetSubjectsUseCase implements GetSubjectsUseCaseContract {
  const GetSubjectsUseCase(this._repository);

  final SubjectRepositoryContract _repository;

  @override
  Future<AppResult<List<Subject>>> call({required bool archived}) =>
      _repository.getSubjects(archived: archived);
}
