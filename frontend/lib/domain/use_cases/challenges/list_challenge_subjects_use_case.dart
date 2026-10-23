import '../../models/challenges/challenge_references.dart';
import '../../models/result/app_result.dart';
import '../../repositories/challenge_references_repository_contract.dart';

/// Asignaturas que se pueden asociar a un reto o tarea.
abstract interface class ListChallengeSubjectsUseCaseContract {
  Future<AppResult<List<ChallengeSubjectOption>>> call();
}

class ListChallengeSubjectsUseCase
    implements ListChallengeSubjectsUseCaseContract {
  const ListChallengeSubjectsUseCase(this._repository);

  final ChallengeReferencesRepositoryContract _repository;

  @override
  Future<AppResult<List<ChallengeSubjectOption>>> call() =>
      _repository.subjects();
}
