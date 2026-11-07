import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/run.dart';
import '../../domain/repositories/run_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../local_data_source/run_recording_storage.dart';
import '../local_data_source/run_tracker_data_source.dart';
import '../remote_data_source/training/run_remote_data_source.dart';

/// Implementa [RunRepositoryContract] con [RunRemoteDataSource].
class RunRepository implements RunRepositoryContract {
  const RunRepository(this._remote);

  final RunRemoteDataSource _remote;

  @override
  Future<AppResult<RunSaved>> upload(RunRecording recording) =>
      RepositoryErrorHandler.guard(() => _remote.upload(recording));

  @override
  Future<AppResult<RunDetail>> getRun(String blockId) =>
      RepositoryErrorHandler.guard(() => _remote.getRun(blockId));

  @override
  Future<AppResult<Unit>> deleteRun(String blockId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteRun(blockId);
        return unit;
      });

  @override
  Future<AppResult<RunWeek>> getWeek() =>
      RepositoryErrorHandler.guard(_remote.getWeek);

  @override
  Future<AppResult<List<RunWorkout>>> listWorkouts() =>
      RepositoryErrorHandler.guard(_remote.listWorkouts);

  @override
  Future<AppResult<List<RunWorkout>>> listTemplates() =>
      RepositoryErrorHandler.guard(_remote.listTemplates);

  @override
  Future<AppResult<RunWorkout>> createWorkout(RunWorkout workout) =>
      RepositoryErrorHandler.guard(() => _remote.createWorkout(workout));

  @override
  Future<AppResult<RunWorkout>> updateWorkout(RunWorkout workout) =>
      RepositoryErrorHandler.guard(() => _remote.updateWorkout(workout));

  @override
  Future<AppResult<Unit>> deleteWorkout(String workoutId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteWorkout(workoutId);
        return unit;
      });

  @override
  Future<AppResult<String>> scheduleWorkout(String workoutId, DateTime start) =>
      RepositoryErrorHandler.guard(
        () => _remote.scheduleWorkout(workoutId, start),
      );

  @override
  Future<AppResult<List<PlannedRun>>> listPlanned() =>
      RepositoryErrorHandler.guard(_remote.listPlanned);
}

/// Implementa [RunRecordingRepositoryContract] con [RunRecordingStorage].
class RunRecordingRepository implements RunRecordingRepositoryContract {
  const RunRecordingRepository(this._storage);

  final RunRecordingStorage _storage;

  @override
  Future<AppResult<RunRecording?>> loadCurrent() =>
      RepositoryErrorHandler.guard(_storage.loadCurrent);

  @override
  Future<AppResult<Unit>> saveCurrent(RunRecording? recording) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.saveCurrent(recording);
        return unit;
      });

  @override
  Future<AppResult<List<RunRecording>>> pending() =>
      RepositoryErrorHandler.guard(_storage.pending);

  @override
  Future<AppResult<Unit>> addPending(RunRecording recording) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.addPending(recording);
        return unit;
      });

  @override
  Future<AppResult<Unit>> removePending(String clientKey) =>
      RepositoryErrorHandler.guard(() async {
        await _storage.removePending(clientKey);
        return unit;
      });
}

/// Implementa [RunTrackerRepositoryContract] con [RunTrackerDataSource]. El
/// aviso fijo y la vibración son ayudas: si fallan, la grabación sigue.
class RunTrackerRepository implements RunTrackerRepositoryContract {
  const RunTrackerRepository(this._tracker);

  final RunTrackerDataSource _tracker;

  @override
  bool get supported => _tracker.supported;

  @override
  Future<AppResult<bool>> locationServiceEnabled() =>
      RepositoryErrorHandler.guard(_tracker.serviceEnabled);

  @override
  Future<AppResult<RunFix?>> currentPosition() =>
      RepositoryErrorHandler.guard(_tracker.currentPosition);

  @override
  Stream<AppResult<RunFix>> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  }) => RepositoryErrorHandler.guardStream(
    () => _tracker.watch(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      channelName: channelName,
    ),
  );

  @override
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  }) async {
    await RepositoryErrorHandler.guard(() async {
      await _tracker.updateNotification(
        title: title,
        text: text,
        channelName: channelName,
      );
      return unit;
    });
  }

  @override
  Future<void> vibrate() async {
    await RepositoryErrorHandler.guard(() async {
      await _tracker.vibrate();
      return unit;
    });
  }
}
