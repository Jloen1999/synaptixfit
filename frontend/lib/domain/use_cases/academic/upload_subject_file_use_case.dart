import '../../models/academic/subject_file.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_file_repository_contract.dart';

/// Sube un archivo a una asignatura.
abstract interface class UploadSubjectFileUseCaseContract {
  Future<AppResult<SubjectFile>> call(
    String subjectId,
    FileUploadPayload payload, {
    void Function(double progress)? onProgress,
  });
}

class UploadSubjectFileUseCase implements UploadSubjectFileUseCaseContract {
  const UploadSubjectFileUseCase(this._repository);

  final SubjectFileRepositoryContract _repository;

  @override
  Future<AppResult<SubjectFile>> call(
    String subjectId,
    FileUploadPayload payload, {
    void Function(double progress)? onProgress,
  }) => _repository.uploadFile(subjectId, payload, onProgress: onProgress);
}
