import '../../models/result/app_result.dart';
import '../../models/training/media_credit.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Crédito de la foto y el vídeo de un ejercicio (vacío si no hay que atribuir).
abstract interface class GetExerciseMediaCreditsUseCaseContract {
  Future<AppResult<List<MediaCredit>>> call(String exerciseId);
}

class GetExerciseMediaCreditsUseCase
    implements GetExerciseMediaCreditsUseCaseContract {
  const GetExerciseMediaCreditsUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<List<MediaCredit>>> call(String exerciseId) =>
      _repository.getMediaCredits(exerciseId);
}
