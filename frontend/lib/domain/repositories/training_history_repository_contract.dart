import '../models/result/app_result.dart';
import '../models/training/session_history.dart';
import '../models/training/training_page.dart';
import '../models/training/exercise_progress.dart';

/// Historial de entrenamiento con nombres y récords personales.
abstract interface class TrainingHistoryRepositoryContract {
  Future<AppResult<TrainingPage<SessionHistoryEntry>>> getHistory({
    int page = 0,
    int size = 20,
  });

  Future<AppResult<List<PersonalRecord>>> getPersonalRecords();

  /// Mejor serie de la última sesión de cada ejercicio (referencia al registrar).
  Future<AppResult<List<PersonalRecord>>> getLastPerformance();

  /// Resumen destacado de una sesión terminada.
  Future<AppResult<SessionHighlights>> getSessionHighlights(String sessionId);

  /// Evolución de un ejercicio: peso máximo estimado por día (ADR 0032).
  Future<AppResult<List<ExerciseProgressPoint>>> getExerciseProgress(
    String exerciseId,
  );
}
