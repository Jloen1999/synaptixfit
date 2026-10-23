import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Borra un ejercicio (o lo desactiva si está en uso).
abstract interface class DeleteAdminExerciseUseCaseContract {
  Future<AppResult<AdminExerciseDeletion>> call(String exerciseId);
}

class DeleteAdminExerciseUseCase implements DeleteAdminExerciseUseCaseContract {
  const DeleteAdminExerciseUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExerciseDeletion>> call(String exerciseId) =>
      _repository.delete(exerciseId);
}
