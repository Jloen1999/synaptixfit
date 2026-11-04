import '../../domain/models/result/app_result.dart';
import '../../domain/models/training/exercise.dart';
import '../../domain/models/training/exercise_guide.dart';
import '../../domain/models/training/training_page.dart';
import '../../domain/repositories/exercise_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/training/exercise_remote_data_source.dart';

/// Implementa [ExerciseRepositoryContract] con [ExerciseRemoteDataSource].
class ExerciseRepository implements ExerciseRepositoryContract {
  ExerciseRepository(this._remote);

  final ExerciseRemoteDataSource _remote;

  @override
  Future<AppResult<TrainingPage<Exercise>>> search(
    ExerciseSearchCriteria criteria, {
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(() async {
    final result = await _remote.search(criteria, page: page, size: size);
    return TrainingPage(
      items: result.items.map((e) => e.toDomain()).toList(),
      page: result.page,
      totalPages: result.totalPages,
      totalItems: result.totalItems,
    );
  });

  @override
  Future<AppResult<Exercise>> getExercise(String exerciseId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.get(exerciseId)).toDomain(),
      );

  @override
  Future<AppResult<List<Exercise>>> getAlternatives(String exerciseId) =>
      RepositoryErrorHandler.guard(
        () async => [
          for (final e in await _remote.alternatives(exerciseId)) e.toDomain(),
        ],
      );

  @override
  Future<AppResult<SessionBookends>> getBookends(List<String> exerciseIds) =>
      RepositoryErrorHandler.guard(() async {
        final b = await _remote.bookends(exerciseIds);
        return SessionBookends(
          warmUp: [for (final e in b.warmUp) e.toDomain()],
          coolDown: [for (final e in b.coolDown) e.toDomain()],
        );
      });

  @override
  Future<AppResult<ExerciseFilterOptions>> getFilters() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.filters()).toDomain(),
      );

  @override
  Future<AppResult<ExerciseTips>> getTips(String exerciseId) =>
      RepositoryErrorHandler.guard(() => _remote.tips(exerciseId));

  @override
  Future<AppResult<ExerciseNote?>> getNote(String exerciseId) =>
      RepositoryErrorHandler.guard(() => _remote.note(exerciseId));

  @override
  Future<AppResult<ExerciseNote?>> saveNote(String exerciseId, String text) =>
      RepositoryErrorHandler.guard(() => _remote.saveNote(exerciseId, text));
}
