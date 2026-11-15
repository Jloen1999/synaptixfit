import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// El «Entrenamos juntos» de una sesión propia, o `null` si no lo es.
abstract interface class FindWorkoutTogetherBySessionUseCaseContract {
  Future<AppResult<WorkoutTogether?>> call(String sessionId);
}

/// Implementa [FindWorkoutTogetherBySessionUseCaseContract] con [TogetherRepositoryContract].
class FindWorkoutTogetherBySessionUseCase
    implements FindWorkoutTogetherBySessionUseCaseContract {
  const FindWorkoutTogetherBySessionUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<WorkoutTogether?>> call(String sessionId) =>
      _repository.workoutBySession(sessionId);
}
