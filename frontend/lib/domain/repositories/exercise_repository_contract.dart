import '../models/result/app_result.dart';
import '../models/training/exercise.dart';
import '../models/training/training_page.dart';

/// Catálogo de ejercicios (`/api/v1/exercises`).
abstract interface class ExerciseRepositoryContract {
  Future<AppResult<TrainingPage<Exercise>>> search(
    ExerciseSearchCriteria criteria, {
    int page = 0,
    int size = 20,
  });

  Future<AppResult<Exercise>> getExercise(String exerciseId);

  Future<AppResult<ExerciseFilterOptions>> getFilters();

  /// Ejercicios que pueden sustituir a [exerciseId], del más parecido al menos.
  Future<AppResult<List<Exercise>>> getAlternatives(String exerciseId);

  /// Calentamiento y vuelta a la calma para los ejercicios de una sesión.
  Future<AppResult<SessionBookends>> getBookends(List<String> exerciseIds);
}
