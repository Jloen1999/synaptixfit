import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/local_data_source/run_recording_storage.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/run.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';
import 'package:synaptixfit/domain/repositories/run_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/training/finish_run_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/upload_pending_runs_use_case.dart';

/// Terminar una carrera y subir la cola sin duplicar (clave idempotente).
void main() {
  late _Local local;
  late _Remote remote;

  final recording = RunRecording(
    clientKey: '2f1c0d1e-1111-4222-8333-444455556666',
    kind: ActivityKind.run,
    startedAt: DateTime.utc(2026, 11, 7, 17),
    points: const [
      RunTrackPoint(
        latitude: 40,
        longitude: -3.7,
        altitude: 650,
        accuracy: 4,
        offsetSeconds: 0,
        segment: 0,
      ),
      RunTrackPoint(
        latitude: 40.001,
        longitude: -3.7,
        accuracy: 5,
        offsetSeconds: 30.5,
        segment: 1,
      ),
    ],
    workoutId: 'w1',
    plannedBlockId: 'b1',
  );

  setUp(() {
    local = _Local();
    remote = _Remote();
  });

  test('con conexión se guarda y sale de la cola', () async {
    final result = await FinishRunUseCase(local, remote)(recording, effort: 7);
    expect(result.valueOrNull?.run.blockId, 'block-1');
    expect(remote.sent.single.effort, 7);
    expect(local.queue, isEmpty);
    expect(local.current, isNull);
  });

  test('sin conexión queda en la cola y luego se sube una sola vez', () async {
    remote.offline = true;
    final result = await FinishRunUseCase(local, remote)(recording, effort: 6);
    expect(result, isA<Success<RunSaved?, AppError>>());
    expect(result.valueOrNull, isNull);
    expect(local.queue.keys, [recording.clientKey]);

    remote.offline = false;
    final uploaded = await UploadPendingRunsUseCase(local, remote)();
    expect(uploaded.valueOrNull, hasLength(1));
    expect(local.queue, isEmpty);
    // La misma clave en los dos intentos: el servidor no la duplica.
    expect(remote.sent.map((r) => r.clientKey).toSet(), {recording.clientKey});
    final again = await UploadPendingRunsUseCase(local, remote)();
    expect(again.valueOrNull, isEmpty);
  });

  test(
    'si el servidor la rechaza por una regla, sale de la cola con su error',
    () async {
      remote.reject = 'RUN_TOO_SHORT';
      final result = await FinishRunUseCase(local, remote)(
        recording,
        effort: 5,
      );
      expect(result.errorOrNull, const AppError.business('RUN_TOO_SHORT'));
      expect(local.queue, isEmpty);
    },
  );

  test('la carrera guardada en el teléfono se recupera igual', () {
    final back = RunRecordingStorage.decode(
      RunRecordingStorage.encode(
        recording.copyWith(effort: 8, pausedSeconds: 42),
      ),
    );
    expect(back.clientKey, recording.clientKey);
    expect(back.points, recording.points);
    expect(back.effort, 8);
    expect(back.pausedSeconds, 42);
    expect(back.plannedBlockId, 'b1');
  });
}

class _Local implements RunRecordingRepositoryContract {
  RunRecording? current;
  final queue = <String, RunRecording>{};

  @override
  Future<AppResult<RunRecording?>> loadCurrent() async => Success(current);

  @override
  Future<AppResult<Unit>> saveCurrent(RunRecording? recording) async {
    current = recording;
    return const Success(unit);
  }

  @override
  Future<AppResult<List<RunRecording>>> pending() async =>
      Success(queue.values.toList());

  @override
  Future<AppResult<Unit>> addPending(RunRecording recording) async {
    queue[recording.clientKey] = recording;
    return const Success(unit);
  }

  @override
  Future<AppResult<Unit>> removePending(String clientKey) async {
    queue.remove(clientKey);
    return const Success(unit);
  }
}

class _Remote implements RunRepositoryContract {
  bool offline = false;
  String? reject;
  final sent = <RunRecording>[];

  @override
  Future<AppResult<RunSaved>> upload(RunRecording recording) async {
    if (offline) return const Failure(AppError.network());
    if (reject case final code?) return Failure(AppError.business(code));
    sent.add(recording);
    return Success(
      RunSaved(
        run: RunDetail(
          blockId: 'block-1',
          kind: recording.kind,
          startedAt: recording.startedAt,
          endedAt: recording.startedAt,
          distanceMeters: 111,
          movingSeconds: 30,
          elevationGainMeters: 0,
          effort: recording.effort ?? 0,
        ),
        xpDelta: 15,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
