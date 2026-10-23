import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Materiales con repaso pendiente.
abstract interface class GetDueStudyMaterialsUseCaseContract {
  Future<AppResult<List<StudyMaterial>>> call({int limit = 20});
}

class GetDueStudyMaterialsUseCase
    implements GetDueStudyMaterialsUseCaseContract {
  const GetDueStudyMaterialsUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<List<StudyMaterial>>> call({int limit = 20}) =>
      _repository.getDueMaterials(limit: limit);
}
