import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Acepta entrenar juntos hoy.
abstract interface class JoinWorkoutTogetherUseCaseContract {
  Future<AppResult<WorkoutTogether>> call(String id);
}

/// Implementa [JoinWorkoutTogetherUseCaseContract] con [TogetherRepositoryContract].
class JoinWorkoutTogetherUseCase implements JoinWorkoutTogetherUseCaseContract {
  const JoinWorkoutTogetherUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<WorkoutTogether>> call(String id) =>
      _repository.joinWorkout(id);
}
