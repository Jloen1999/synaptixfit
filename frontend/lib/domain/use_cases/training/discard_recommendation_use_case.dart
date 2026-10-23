import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/training_repository_contract.dart';

/// Descarta una sugerencia.
abstract interface class DiscardRecommendationUseCaseContract {
  Future<AppResult<Unit>> call(String recommendationId);
}

class DiscardRecommendationUseCase
    implements DiscardRecommendationUseCaseContract {
  const DiscardRecommendationUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String recommendationId) =>
      _repository.discardRecommendation(recommendationId);
}
