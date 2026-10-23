import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Quita un material del repaso.
abstract interface class DeleteStudyMaterialUseCaseContract {
  Future<AppResult<Unit>> call(String materialId);
}

class DeleteStudyMaterialUseCase implements DeleteStudyMaterialUseCaseContract {
  const DeleteStudyMaterialUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String materialId) =>
      _repository.deleteMaterial(materialId);
}
