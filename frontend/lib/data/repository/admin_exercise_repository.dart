import '../../domain/models/admin/admin_exercise.dart';
import '../../domain/models/admin/admin_page.dart';
import '../../domain/models/admin/admin_queries.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/admin_exercise_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/admin/admin_exercise_remote_data_source.dart';
import '../remote_data_source/admin/dto/admin_exercise_dto.dart';

class AdminExerciseRepository implements AdminExerciseRepositoryContract {
  AdminExerciseRepository(this._remote);

  final AdminExerciseRemoteDataSource _remote;

  @override
  Future<AppResult<AdminPage<AdminExercise>>> search({
    required AdminExerciseQuery query,
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(() async {
    final text = query.text.trim();
    final result = await _remote.search({
      if (text.isNotEmpty) 'q': text,
      if (query.difficulty != null) 'difficulty': query.difficulty!.apiValue,
      if (query.modality != null) 'modality': query.modality!.apiValue,
      'includeInactive': query.includeInactive,
      'page': page,
      'size': size,
    });
    return AdminPage<AdminExercise>(
      items: [for (final dto in result.items) dto.toDomain()],
      page: result.page,
      size: result.size,
      totalItems: result.totalItems,
      totalPages: result.totalPages,
    );
  });

  @override
  Future<AppResult<AdminExercise>> get(String exerciseId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.get(exerciseId)).toDomain(),
      );

  @override
  Future<AppResult<AdminExercise>> create(AdminExerciseDraft draft) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.create(
          AdminExerciseRequest.fromDraft(draft),
        )).toDomain(),
      );

  @override
  Future<AppResult<AdminExercise>> update(
    String exerciseId,
    AdminExerciseDraft draft,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.update(
      exerciseId,
      AdminExerciseRequest.fromDraft(draft),
    )).toDomain(),
  );

  @override
  Future<AppResult<AdminExerciseNames>> getNames(String exerciseId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.names(exerciseId)).toDomain(),
      );

  @override
  Future<AppResult<AdminExerciseNames>> suggestNames(String spanishName) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.suggestNames(spanishName.trim())).toDomain(),
      );

  @override
  Future<AppResult<AdminExercise>> setActive(
    String exerciseId, {
    required bool active,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setActive(exerciseId, active)).toDomain(),
  );

  @override
  Future<AppResult<AdminExerciseDeletion>> delete(String exerciseId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.delete(exerciseId)).toDomain(),
      );

  @override
  Future<AppResult<AdminExerciseOptions>> getOptions() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.options()).toDomain(),
      );
}
