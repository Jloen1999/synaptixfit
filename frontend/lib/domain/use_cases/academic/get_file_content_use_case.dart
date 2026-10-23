import '../../models/academic/subject_file.dart';
import '../../models/result/app_result.dart';
import '../../repositories/subject_file_repository_contract.dart';

/// Metadatos, URL firmada y (opcionalmente) bytes de un archivo.
abstract interface class GetFileContentUseCaseContract {
  Future<AppResult<FileContent>> call(String fileId, {required bool withBytes});
}

class GetFileContentUseCase implements GetFileContentUseCaseContract {
  const GetFileContentUseCase(this._repository);

  final SubjectFileRepositoryContract _repository;

  @override
  Future<AppResult<FileContent>> call(
    String fileId, {
    required bool withBytes,
  }) => _repository.getFileContent(fileId, withBytes: withBytes);
}
