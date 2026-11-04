import '../../models/result/app_result.dart';
import '../../models/training/exercise_progress.dart';
import '../../repositories/training_history_repository_contract.dart';

/// Evolución de un ejercicio del usuario (puntos de la gráfica, del más
/// antiguo al más reciente).
abstract interface class GetExerciseProgressUseCaseContract {
  Future<AppResult<List<ExerciseProgressPoint>>> call(String exerciseId);
}

class GetExerciseProgressUseCase implements GetExerciseProgressUseCaseContract {
  const GetExerciseProgressUseCase(this._repository);

  final TrainingHistoryRepositoryContract _repository;

  @override
  Future<AppResult<List<ExerciseProgressPoint>>> call(String exerciseId) =>
      _repository.getExerciseProgress(exerciseId);
}
