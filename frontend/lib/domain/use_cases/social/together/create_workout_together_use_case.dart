import '../../../models/result/app_result.dart';
import '../../../models/social/together.dart';
import '../../../repositories/together_repository_contract.dart';

/// Invita a amigos a hacer hoy un día de mi rutina (sin día, el siguiente por hacer).
abstract interface class CreateWorkoutTogetherUseCaseContract {
  Future<AppResult<WorkoutTogether>> call({
    required String routineId,
    String? dayId,
    required List<String> friendIds,
  });
}

/// Implementa [CreateWorkoutTogetherUseCaseContract] con [TogetherRepositoryContract].
class CreateWorkoutTogetherUseCase
    implements CreateWorkoutTogetherUseCaseContract {
  const CreateWorkoutTogetherUseCase(this._repository);

  final TogetherRepositoryContract _repository;

  @override
  Future<AppResult<WorkoutTogether>> call({
    required String routineId,
    String? dayId,
    required List<String> friendIds,
  }) => _repository.createWorkout(
    routineId: routineId,
    dayId: dayId,
    friendIds: friendIds,
  );
}
