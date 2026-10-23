import '../models/admin/admin_exercise.dart';
import '../models/admin/admin_page.dart';
import '../models/admin/admin_queries.dart';
import '../models/result/app_result.dart';

/// Catálogo de ejercicios desde el panel (`/api/v1/admin/exercises/**`).
abstract interface class AdminExerciseRepositoryContract {
  Future<AppResult<AdminPage<AdminExercise>>> search({
    required AdminExerciseQuery query,
    required int page,
    required int size,
  });

  Future<AppResult<AdminExercise>> get(String exerciseId);

  Future<AppResult<AdminExercise>> create(AdminExerciseDraft draft);

  Future<AppResult<AdminExercise>> update(
    String exerciseId,
    AdminExerciseDraft draft,
  );

  Future<AppResult<AdminExercise>> setActive(
    String exerciseId, {
    required bool active,
  });

  Future<AppResult<AdminExerciseDeletion>> delete(String exerciseId);

  /// Músculos, partes del cuerpo y equipamiento (`/api/v1/exercises/filters`).
  Future<AppResult<AdminExerciseOptions>> getOptions();
}
