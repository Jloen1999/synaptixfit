import '../../domain/models/planner/focus.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/focus_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/planner/planner_remote_data_source.dart';

class FocusRepository implements FocusRepositoryContract {
  FocusRepository(this._remote);

  final PlannerRemoteDataSource _remote;

  @override
  Future<AppResult<FocusSessionResult>> recordSession(
    FocusSessionRecord record,
  ) => RepositoryErrorHandler.guard(() async {
    final response = await _remote.recordFocusSession({
      'phase': record.phase.apiValue,
      'durationMinutes': record.durationMinutes,
      'cycles': record.cycles,
      'completed': record.completed,
      if (record.blockId != null) 'blockId': record.blockId,
      if (record.subjectId != null) 'subjectId': record.subjectId,
    });
    return response.toDomain();
  });

  @override
  Future<AppResult<FocusPlan>> getPlan() => RepositoryErrorHandler.guard(
    () async => (await _remote.getFocusPlan()).toDomain(),
  );

  @override
  Future<AppResult<FocusStats>> getStats() => RepositoryErrorHandler.guard(
    () async => (await _remote.getFocusStats()).toDomain(),
  );
}
