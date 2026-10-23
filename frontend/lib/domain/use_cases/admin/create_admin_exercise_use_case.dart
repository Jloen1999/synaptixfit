import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Da de alta un ejercicio.
abstract interface class CreateAdminExerciseUseCaseContract {
  Future<AppResult<AdminExercise>> call(AdminExerciseDraft draft);
}

class CreateAdminExerciseUseCase implements CreateAdminExerciseUseCaseContract {
  const CreateAdminExerciseUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExercise>> call(AdminExerciseDraft draft) =>
      _repository.create(draft);
}
