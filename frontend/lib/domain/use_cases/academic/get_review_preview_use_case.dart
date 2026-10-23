import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Intervalo resultante de cada autoevaluación.
abstract interface class GetReviewPreviewUseCaseContract {
  Future<AppResult<ReviewPreview>> call(String materialId);
}

class GetReviewPreviewUseCase implements GetReviewPreviewUseCaseContract {
  const GetReviewPreviewUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<ReviewPreview>> call(String materialId) =>
      _repository.getReviewPreview(materialId);
}
