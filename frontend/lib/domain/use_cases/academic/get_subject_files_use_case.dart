import '../../models/academic/subject_file.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_file_repository_contract.dart';

/// Archivos de una asignatura.
abstract interface class GetSubjectFilesUseCaseContract {
  Future<AppResult<List<SubjectFile>>> call(String subjectId);
}

class GetSubjectFilesUseCase implements GetSubjectFilesUseCaseContract {
  const GetSubjectFilesUseCase(this._repository);

  final SubjectFileRepositoryContract _repository;

  @override
  Future<AppResult<List<SubjectFile>>> call(String subjectId) =>
      _repository.getFiles(subjectId);
}
