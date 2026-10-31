import '../../models/admin/admin_exercise.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Propuesta de la IA del nombre en los demás idiomas (se revisa antes de
/// guardar).
abstract interface class SuggestAdminExerciseNamesUseCaseContract {
  Future<AppResult<AdminExerciseNames>> call(String spanishName);
}

class SuggestAdminExerciseNamesUseCase
    implements SuggestAdminExerciseNamesUseCaseContract {
  const SuggestAdminExerciseNamesUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminExerciseNames>> call(String spanishName) =>
      _repository.suggestNames(spanishName);
}
