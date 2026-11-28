import '../../models/result/app_result.dart';
import '../../models/training/session.dart';
import '../../repositories/training_repository_contract.dart';

/// «Añadir ejercicio» a una sesión libre en curso (ADR 0067).
abstract interface class AddSessionExerciseUseCaseContract {
  Future<AppResult<TrainingSession>> call(String sessionId, String exerciseId);
}

class AddSessionExerciseUseCase implements AddSessionExerciseUseCaseContract {
  const AddSessionExerciseUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingSession>> call(
    String sessionId,
    String exerciseId,
  ) => _repository.addSessionExercise(sessionId, exerciseId);
}
