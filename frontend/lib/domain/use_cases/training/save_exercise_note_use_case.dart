import '../../models/result/app_result.dart';
import '../../models/training/exercise_guide.dart';
import '../../repositories/exercise_repository_contract.dart';

/// Guarda la nota propia sobre un ejercicio; vacía, la borra (devuelve nula).
abstract interface class SaveExerciseNoteUseCaseContract {
  Future<AppResult<ExerciseNote?>> call(String exerciseId, String text);
}

class SaveExerciseNoteUseCase implements SaveExerciseNoteUseCaseContract {
  const SaveExerciseNoteUseCase(this._repository);

  final ExerciseRepositoryContract _repository;

  @override
  Future<AppResult<ExerciseNote?>> call(String exerciseId, String text) =>
      _repository.saveNote(exerciseId, text.trim());
}
