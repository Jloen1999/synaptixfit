import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Un ejercicio del catálogo.
abstract interface class GetAdminExerciseUseCaseContract {
  Future<AppResult<AdminExercise>> call(String exerciseId);
}

class GetAdminExerciseUseCase implements GetAdminExerciseUseCaseContract {
  const GetAdminExerciseUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExercise>> call(String exerciseId) =>
      _repository.get(exerciseId);
}
