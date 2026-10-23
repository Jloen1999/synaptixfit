import '../../errors/app_error.dart';
import '../../models/academic/teaching_guide_import.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/teaching_guide_import_repository_contract.dart';

/// Consulta la importación cada [interval] hasta que deja de analizarse
/// (lista, fallida o aplicada) y emite cada estado. Aguanta hasta
/// [maxNetworkErrors] cortes de red seguidos (móvil en un ascensor); después
/// emite el error. El servidor da por fallido un análisis colgado, así que la
/// espera siempre termina.
abstract interface class AwaitTeachingGuideImportUseCaseContract {
  Stream<AppResult<TeachingGuideImport>> call(
    String importId, {
    Duration interval,
  });
}

class AwaitTeachingGuideImportUseCase
    implements AwaitTeachingGuideImportUseCaseContract {
  const AwaitTeachingGuideImportUseCase(this._repository);

  final TeachingGuideImportRepositoryContract _repository;

  static const maxNetworkErrors = 3;

  @override
  Stream<AppResult<TeachingGuideImport>> call(
    String importId, {
    Duration interval = const Duration(seconds: 2),
  }) async* {
    var networkErrors = 0;
    while (true) {
      final result = await _repository.get(importId);
      if (result case Failure(
        error: NetworkError(),
      ) when ++networkErrors < maxNetworkErrors) {
        await Future<void>.delayed(interval);
        continue;
      }
      if (result is Success) networkErrors = 0;
      yield result;
      final keepWaiting = switch (result) {
        Success(:final value) => value.status.isRunning,
        Failure() => false,
      };
      if (!keepWaiting) return;
      await Future<void>.delayed(interval);
    }
  }
}
