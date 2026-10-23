import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Opciones de músculos, partes del cuerpo y equipamiento.
abstract interface class GetAdminExerciseOptionsUseCaseContract {
  Future<AppResult<AdminExerciseOptions>> call();
}

class GetAdminExerciseOptionsUseCase
    implements GetAdminExerciseOptionsUseCaseContract {
  const GetAdminExerciseOptionsUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExerciseOptions>> call() => _repository.getOptions();
}
