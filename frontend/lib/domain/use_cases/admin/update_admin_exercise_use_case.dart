import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Edita un ejercicio.
abstract interface class UpdateAdminExerciseUseCaseContract {
  Future<AppResult<AdminExercise>> call(
    String exerciseId,
    AdminExerciseDraft draft,
  );
}

class UpdateAdminExerciseUseCase implements UpdateAdminExerciseUseCaseContract {
  const UpdateAdminExerciseUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExercise>> call(
    String exerciseId,
    AdminExerciseDraft draft,
  ) => _repository.update(exerciseId, draft);
}
