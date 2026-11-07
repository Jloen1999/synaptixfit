import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// «Esta semana» de Correr: distancia, tiempo, desnivel y salidas.
abstract interface class GetRunWeekUseCaseContract {
  Future<AppResult<RunWeek>> call();
}

class GetRunWeekUseCase implements GetRunWeekUseCaseContract {
  const GetRunWeekUseCase(this._repository);

  final RunRepositoryContract _repository;

  @override
  Future<AppResult<RunWeek>> call() => _repository.getWeek();
}
