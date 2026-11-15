import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Detalle de un «Entrenamos juntos» con quién tiene hecho cada ejercicio.
abstract interface class GetWorkoutTogetherUseCaseContract {
  Future<AppResult<WorkoutTogether>> call(String id);
}

/// Implementa [GetWorkoutTogetherUseCaseContract] con [TogetherRepositoryContract].
class GetWorkoutTogetherUseCase implements GetWorkoutTogetherUseCaseContract {
  const GetWorkoutTogetherUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<WorkoutTogether>> call(String id) => _repository.workout(id);
}
