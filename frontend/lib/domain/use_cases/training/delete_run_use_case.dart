import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/run_repository_contract.dart';

/// Borra una carrera (resta su XP y su carga física).
abstract interface class DeleteRunUseCaseContract {
  Future<AppResult<Unit>> call(String blockId);
}

class DeleteRunUseCase implements DeleteRunUseCaseContract {
  const DeleteRunUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String blockId) =>
      _repository.deleteRun(blockId);
}
