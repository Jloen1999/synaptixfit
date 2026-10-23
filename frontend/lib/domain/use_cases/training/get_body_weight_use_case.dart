import '../../models/result/app_result.dart';
import '../../repositories/training_repository_contract.dart';

/// Peso corporal del perfil (para estimar calorías).
abstract interface class GetBodyWeightUseCaseContract {
  Future<AppResult<double?>> call();
}

class GetBodyWeightUseCase implements GetBodyWeightUseCaseContract {
  const GetBodyWeightUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<double?>> call() => _repository.getBodyWeight();
}
