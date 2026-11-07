import '../../errors/app_error.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Termina una carrera con su «¿Cuánto te ha costado?»: la pone en la cola del
/// teléfono, olvida la carrera en curso y la intenta subir. Sin conexión
/// o con cualquier fallo que no sea una regla, devuelve `null` (queda en la
/// cola y se sube sola más tarde, sin duplicarse): una grabación nunca se pierde
/// por un fallo de red o del servidor. Solo si el servidor la rechaza por una
/// regla (muy corta, muy antigua, ruta enorme) sale de la cola y se devuelve el
/// error para explicarlo.
abstract interface class FinishRunUseCaseContract {
  Future<AppResult<RunSaved?>> call(
    RunRecording recording, {
    required int effort,
  });
}

class FinishRunUseCase implements FinishRunUseCaseContract {
  const FinishRunUseCase(this._local, this._remote);

  final RunRecordingRepositoryContract _local;
  final RunRepositoryContract _remote;

  @override
  Future<AppResult<RunSaved?>> call(
    RunRecording recording, {
    required int effort,
  }) async {
    final finished = recording.copyWith(effort: effort, pausedAt: null);
    final queued = await _local.addPending(finished);
    if (queued case Failure(:final error)) return Failure(error);
    await _local.saveCurrent(null);
    final result = await _remote.upload(finished);
    switch (result) {
      case Success(:final value):
        await _local.removePending(finished.clientKey);
        return Success(value);
      case Failure(:final error) when isRejected(error):
        await _local.removePending(finished.clientKey);
        return Failure(error);
      case Failure():
        return const Success(null);
    }
  }

  /// Códigos con los que el servidor rechaza la carrera por una regla: no se
  /// arreglarían reintentando (ADR 0037).
  static const rejectedCodes = {
    'RUN_TOO_SHORT',
    'RUN_OUT_OF_RANGE',
    'RUN_ROUTE_TOO_LARGE',
  };

  /// Solo estos fallos sacan la carrera de la cola; cualquier otro (red,
  /// servidor, sesión caducada, un proxy) la deja para reintentar.
  static bool isRejected(AppError error) => switch (error) {
    BusinessError(:final code) => rejectedCodes.contains(code),
    ValidationError() => true,
    _ => false,
  };
}
