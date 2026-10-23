import '../../models/result/app_result.dart';
import '../../models/training/recommendation.dart';
import '../../models/training/training_page.dart';
import '../../repositories/training_repository_contract.dart';

/// Sugerencias de entrenamiento.
abstract interface class GetRecommendationsUseCaseContract {
  Future<AppResult<TrainingPage<Recommendation>>> call({
    bool? applied,
    int page = 0,
    int size = 20,
  });
}

class GetRecommendationsUseCase implements GetRecommendationsUseCaseContract {
  const GetRecommendationsUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<Recommendation>>> call({
    bool? applied,
    int page = 0,
    int size = 20,
  }) =>
      _repository.getRecommendations(applied: applied, page: page, size: size);
}
