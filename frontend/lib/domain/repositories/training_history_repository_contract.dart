import '../models/result/app_result.dart';
import '../models/training/session_history.dart';
import '../models/training/training_page.dart';

/// Historial de entrenamiento con nombres y récords personales.
abstract interface class TrainingHistoryRepositoryContract {
  Future<AppResult<TrainingPage<SessionHistoryEntry>>> getHistory({
    int page = 0,
    int size = 20,
  });

  Future<AppResult<List<PersonalRecord>>> getPersonalRecords();

  /// Mejor serie de la última sesión de cada ejercicio (referencia al registrar).
  Future<AppResult<List<PersonalRecord>>> getLastPerformance();
}
