import '../../domain/models/result/app_result.dart';
import '../../domain/models/training/session_history.dart';
import '../../domain/models/training/training_page.dart';
import '../../domain/repositories/training_history_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/training/training_history_remote_data_source.dart';
import '../../domain/models/training/exercise_progress.dart';

/// Implementa [TrainingHistoryRepositoryContract] con [TrainingHistoryRemoteDataSource].
class TrainingHistoryRepository implements TrainingHistoryRepositoryContract {
  TrainingHistoryRepository(this._remote);

  final TrainingHistoryRemoteDataSource _remote;

  @override
  Future<AppResult<TrainingPage<SessionHistoryEntry>>> getHistory({
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(() async {
    final dto = await _remote.history(page: page, size: size);
    return TrainingPage(
      items: [for (final e in dto.items) e.toDomain()],
      page: dto.page,
      totalPages: dto.totalPages,
      totalItems: dto.totalItems,
    );
  });

  @override
  Future<AppResult<List<PersonalRecord>>> getLastPerformance() =>
      RepositoryErrorHandler.guard(
        () async => [
          for (final r in await _remote.lastPerformance()) r.toDomain(),
        ],
      );

  @override
  Future<AppResult<SessionHighlights>> getSessionHighlights(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.highlights(sessionId)).toDomain(),
      );

  @override
  Future<AppResult<List<PersonalRecord>>> getPersonalRecords() =>
      RepositoryErrorHandler.guard(
        () async => [for (final r in await _remote.records()) r.toDomain()],
      );

  @override
  Future<AppResult<List<ExerciseProgressPoint>>> getExerciseProgress(
    String exerciseId,
  ) => RepositoryErrorHandler.guard(() => _remote.exerciseProgress(exerciseId));
}
