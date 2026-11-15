import '../../../models/result/app_result.dart';
import '../../../repositories/together_repository_contract.dart';

/// Empieza (o retoma) mi sesión normal para entrenar juntos y devuelve su id.
abstract interface class StartWorkoutTogetherUseCaseContract {
  Future<AppResult<String>> call(String id);
}

/// Implementa [StartWorkoutTogetherUseCaseContract] con [TogetherRepositoryContract].
class StartWorkoutTogetherUseCase
    implements StartWorkoutTogetherUseCaseContract {
  const StartWorkoutTogetherUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<String>> call(String id) => _repository.startWorkout(id);
}
