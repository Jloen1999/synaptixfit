import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Un material de estudio.
abstract interface class GetStudyMaterialUseCaseContract {
  Future<AppResult<StudyMaterial>> call(String materialId);
}

class GetStudyMaterialUseCase implements GetStudyMaterialUseCaseContract {
  const GetStudyMaterialUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<StudyMaterial>> call(String materialId) =>
      _repository.getMaterial(materialId);
}
