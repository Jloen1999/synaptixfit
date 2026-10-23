import '../../models/challenges/challenge_references.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenge_references_repository_contract.dart';

/// Apuntes y archivos adjuntables de una asignatura.
abstract interface class ListChallengeAttachmentsUseCaseContract {
  Future<AppResult<ChallengeAttachmentOptions>> call(String? subjectId);
}

class ListChallengeAttachmentsUseCase
    implements ListChallengeAttachmentsUseCaseContract {
  const ListChallengeAttachmentsUseCase(this._repository);

  final ChallengeReferencesRepositoryContract _repository;

  @override
  Future<AppResult<ChallengeAttachmentOptions>> call(String? subjectId) =>
      _repository.attachments(subjectId);
}
