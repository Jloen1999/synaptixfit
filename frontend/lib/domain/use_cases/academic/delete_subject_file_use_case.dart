import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/subject_file_repository_contract.dart';

/// Borra un archivo.
abstract interface class DeleteSubjectFileUseCaseContract {
  Future<AppResult<Unit>> call(String fileId);
}

class DeleteSubjectFileUseCase implements DeleteSubjectFileUseCaseContract {
  const DeleteSubjectFileUseCase(this._repository);

  final SubjectFileRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String fileId) => _repository.deleteFile(fileId);
}
