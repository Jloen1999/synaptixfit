import '../../models/result/app_result.dart';
import '../../repositories/challenge_references_repository_contract.dart';

/// URL firmada para abrir el archivo adjunto a una tarea.
abstract interface class GetChallengeFileUrlUseCaseContract {
  Future<AppResult<String>> call(String fileId);
}

class GetChallengeFileUrlUseCase implements GetChallengeFileUrlUseCaseContract {
  const GetChallengeFileUrlUseCase(this._repository);

  final ChallengeReferencesRepositoryContract _repository;

  @override
  Future<AppResult<String>> call(String fileId) => _repository.fileUrl(fileId);
}
