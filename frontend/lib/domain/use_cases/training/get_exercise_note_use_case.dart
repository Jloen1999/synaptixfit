import '../../models/result/app_result.dart';
import '../../models/training/exercise_guide.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Nota propia sobre un ejercicio (nula si no hay).
abstract interface class GetExerciseNoteUseCaseContract {
  Future<AppResult<ExerciseNote?>> call(String exerciseId);
}

class GetExerciseNoteUseCase implements GetExerciseNoteUseCaseContract {
  const GetExerciseNoteUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<ExerciseNote?>> call(String exerciseId) =>
      _repository.getNote(exerciseId);
}
