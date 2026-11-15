import '../../../models/result/app_result.dart';
import '../../../models/result/result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Dice que no a entrenar juntos hoy.
abstract interface class DeclineWorkoutTogetherUseCaseContract {
  Future<AppResult<Unit>> call(String id);
}

/// Implementa [DeclineWorkoutTogetherUseCaseContract] con [TogetherRepositoryContract].
class DeclineWorkoutTogetherUseCase
    implements DeclineWorkoutTogetherUseCaseContract {
  const DeclineWorkoutTogetherUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String id) => _repository.declineWorkout(id);
}
