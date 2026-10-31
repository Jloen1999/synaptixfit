import '../models/planner/deadline.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Entregas y exámenes.
abstract interface class DeadlineRepositoryContract {
  /// [upcoming] = solo pendientes desde hoy; con [includeOverdue], también las
  /// vencidas sin completar de los últimos 30 días (primero).
  Future<AppResult<DeadlinePage>> getDeadlines({
    bool upcoming = false,
    bool includeOverdue = false,
    String? subjectId,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<Deadline>> createDeadline(DeadlineDraft draft);

  /// Sustituye los datos; si [DeadlineDraft.subjectId] es nulo quita la asignatura.
  Future<AppResult<Deadline>> updateDeadline(String id, DeadlineDraft draft);

  Future<AppResult<Unit>> deleteDeadline(String id);

  Future<AppResult<DeadlineCompletion>> setDeadlineCompletion(
    String id, {
    required bool completed,
  });
}
