import '../../domain/models/planner/deadline.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/deadline_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/planner/dto/planner_json.dart';
import '../remote_data_source/planner/planner_remote_data_source.dart';

class DeadlineRepository implements DeadlineRepositoryContract {
  DeadlineRepository(this._remote);

  final PlannerRemoteDataSource _remote;

  static Map<String, dynamic> _body(DeadlineDraft d) => {
    'title': d.title.trim(),
    'type': d.type.apiValue,
    'dueAt': PlannerJson.toInstant(d.dueAt),
    'difficulty': d.difficulty.apiValue,
    'description': d.description?.trim(),
  };

  @override
  Future<AppResult<DeadlinePage>> getDeadlines({
    bool upcoming = false,
    String? subjectId,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.getDeadlines(
      upcoming: upcoming,
      subjectId: subjectId,
      page: page,
      size: size,
    )).toDomain(),
  );

  @override
  Future<AppResult<Deadline>> createDeadline(DeadlineDraft draft) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.createDeadline({
          ..._body(draft),
          'subjectId': draft.subjectId,
        })).toDomain(),
      );

  @override
  Future<AppResult<Deadline>> updateDeadline(String id, DeadlineDraft draft) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.updateDeadline(id, {
          ..._body(draft),
          'subjectId': draft.subjectId,
          'clearSubject': draft.subjectId == null,
        })).toDomain(),
      );

  @override
  Future<AppResult<Unit>> deleteDeadline(String id) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteDeadline(id);
        return unit;
      });

  @override
  Future<AppResult<DeadlineCompletion>> setDeadlineCompletion(
    String id, {
    required bool completed,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setDeadlineCompletion(
      id,
      completed: completed,
    )).toDomain(),
  );
}
