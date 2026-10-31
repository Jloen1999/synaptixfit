import '../../domain/models/planner/active_focus_timer.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/active_focus_timer_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/active_focus_timer_storage.dart';

/// Implementa [ActiveFocusTimerRepositoryContract] con [ActiveFocusTimerStorage].
class ActiveFocusTimerRepository implements ActiveFocusTimerRepositoryContract {
  const ActiveFocusTimerRepository(this._storage);

  final ActiveFocusTimerStorage _storage;

  @override
  Future<AppResult<ActiveFocusTimer?>> load() =>
      RepositoryErrorHandler.guard(_storage.load);

  @override
  Future<AppResult<Unit>> save(ActiveFocusTimer timer) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.save(timer);
        return unit;
      });

  @override
  Future<AppResult<Unit>> clear() => RepositoryErrorHandler.guard(() async {
    await _storage.clear();
    return unit;
  });
}
