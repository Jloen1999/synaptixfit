import '../../models/admin/admin_exercise.dart';
import '../../models/admin/admin_page.dart';
import '../../models/admin/admin_queries.dart';
import '../../models/result/app_result.dart';
import '../../repositories/admin_exercise_repository_contract.dart';

/// Busca ejercicios del catálogo (incluidos inactivos).
abstract interface class SearchAdminExercisesUseCaseContract {
  Future<AppResult<AdminPage<AdminExercise>>> call({
    required AdminExerciseQuery query,
    required int page,
    required int size,
  });
}

class SearchAdminExercisesUseCase
    implements SearchAdminExercisesUseCaseContract {
  const SearchAdminExercisesUseCase(this._repository);

  final AdminExerciseRepositoryContract _repository;

  @override
  Future<AppResult<AdminPage<AdminExercise>>> call({
    required AdminExerciseQuery query,
    required int page,
    required int size,
  }) => _repository.search(query: query, page: page, size: size);
}
