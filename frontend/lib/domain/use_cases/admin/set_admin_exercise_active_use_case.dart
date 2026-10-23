import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Activa o desactiva un ejercicio.
abstract interface class SetAdminExerciseActiveUseCaseContract {
  Future<AppResult<AdminExercise>> call(
    String exerciseId, {
    required bool active,
  });
}

class SetAdminExerciseActiveUseCase
    implements SetAdminExerciseActiveUseCaseContract {
  const SetAdminExerciseActiveUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExercise>> call(
    String exerciseId, {
    required bool active,
  }) => _repository.setActive(exerciseId, active: active);
}
