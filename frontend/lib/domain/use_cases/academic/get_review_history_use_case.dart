import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Historial de repasos.
abstract interface class GetReviewHistoryUseCaseContract {
  Future<AppResult<List<ReviewRecord>>> call(String materialId);
}

class GetReviewHistoryUseCase implements GetReviewHistoryUseCaseContract {
  const GetReviewHistoryUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<List<ReviewRecord>>> call(String materialId) =>
      _repository.getReviewHistory(materialId);
}
