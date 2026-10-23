import '../../models/result/app_result.dart';
import '../../models/training/recommendation.dart';
import '../../repositories/training_repository_contract.dart';

/// Aplica una sugerencia a la rutina.
abstract interface class ApplyRecommendationUseCaseContract {
  Future<AppResult<Recommendation>> call(String recommendationId);
}

class ApplyRecommendationUseCase implements ApplyRecommendationUseCaseContract {
  const ApplyRecommendationUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<Recommendation>> call(String recommendationId) =>
      _repository.applyRecommendation(recommendationId);
}
