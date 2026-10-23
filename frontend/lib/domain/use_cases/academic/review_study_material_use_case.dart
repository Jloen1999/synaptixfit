import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Registra un repaso con su autoevaluación (0-5).
abstract interface class ReviewStudyMaterialUseCaseContract {
  Future<AppResult<ReviewOutcome>> call(String materialId, int quality);
}

class ReviewStudyMaterialUseCase implements ReviewStudyMaterialUseCaseContract {
  const ReviewStudyMaterialUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<ReviewOutcome>> call(String materialId, int quality) =>
      _repository.review(materialId, quality);
}
