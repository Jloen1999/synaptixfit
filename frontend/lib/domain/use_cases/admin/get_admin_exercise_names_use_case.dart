import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Nombre de un ejercicio en los demás idiomas, para editarlo.
abstract interface class GetAdminExerciseNamesUseCaseContract {
  Future<AppResult<AdminExerciseNames>> call(String exerciseId);
}

class GetAdminExerciseNamesUseCase
    implements GetAdminExerciseNamesUseCaseContract {
  const GetAdminExerciseNamesUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExerciseNames>> call(String exerciseId) =>
      _repository.getNames(exerciseId);
}
