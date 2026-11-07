import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// Detalle de una carrera (cifras, tramos por km y ruta).
abstract interface class GetRunUseCaseContract {
  Future<AppResult<RunDetail>> call(String blockId);
}

class GetRunUseCase implements GetRunUseCaseContract {
  const GetRunUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<RunDetail>> call(String blockId) =>
      _repository.getRun(blockId);
}
