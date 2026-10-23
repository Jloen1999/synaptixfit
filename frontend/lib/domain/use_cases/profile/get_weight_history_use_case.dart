import '../../models/profile/wellness_history.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Historial de peso.
abstract interface class GetWeightHistoryUseCaseContract {
  Future<AppResult<List<WeightRecord>>> call();
}

class GetWeightHistoryUseCase implements GetWeightHistoryUseCaseContract {
  const GetWeightHistoryUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<List<WeightRecord>>> call() =>
      _repository.getWeightHistory();
}
