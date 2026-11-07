import '../../errors/app_error.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Termina una carrera con su «¿Cuánto te ha costado?»: la pone en la cola del
/// teléfono, olvida la carrera en curso y la intenta subir. Sin conexión
/// devuelve `null` (queda en la cola y se sube sola más tarde, sin duplicarse);
/// si el servidor la rechaza por una regla (muy corta, muy antigua), sale de la
/// cola y se devuelve el error para explicarlo.
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
      case Failure(:final error) when isRetriable(error):
        return const Success(null);
      case Failure(:final error):
        await _local.removePending(finished.clientKey);
        return Failure(error);
    }
  }

  /// Errores que se arreglan solos al reintentar (sin conexión, servidor caído,
  /// sesión caducada): la carrera se queda en la cola.
  static bool isRetriable(AppError error) => switch (error) {
    NetworkError() || ServerError() || UnauthorizedError() => true,
    _ => false,
  };
}
