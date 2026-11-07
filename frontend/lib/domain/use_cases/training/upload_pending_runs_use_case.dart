import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';
import 'finish_run_use_case.dart';

/// Sube las carreras que esperaban conexión, de la más antigua a la más nueva.
/// Cada una lleva su clave, así reintentar nunca la duplica. Se para en el
/// primer fallo de red; las que el servidor rechaza por una regla salen de la
/// cola (no se arreglarían reintentando). Devuelve las que se subieron.
abstract interface class UploadPendingRunsUseCaseContract {
  Future<AppResult<List<RunSaved>>> call();
}

class UploadPendingRunsUseCase implements UploadPendingRunsUseCaseContract {
  const UploadPendingRunsUseCase(this._local, this._remote);

  final RunRecordingRepositoryContract _local;
  final RunRepositoryContract _remote;

  @override
  Future<AppResult<List<RunSaved>>> call() async {
    final pending = await _local.pending();
    if (pending case Failure(:final error)) return Failure(error);
    final saved = <RunSaved>[];
    for (final run in pending.valueOrNull ?? const <RunRecording>[]) {
      final result = await _remote.upload(run);
      switch (result) {
        case Success(:final value):
          saved.add(value);
          await _local.removePending(run.clientKey);
        case Failure(:final error) when FinishRunUseCase.isRetriable(error):
          return Success(saved);
        case Failure():
          await _local.removePending(run.clientKey);
      }
    }
    return Success(saved);
  }
}
