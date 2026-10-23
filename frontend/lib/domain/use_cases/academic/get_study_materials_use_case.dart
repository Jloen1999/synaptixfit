import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Materiales de estudio.
abstract interface class GetStudyMaterialsUseCaseContract {
  Future<AppResult<List<StudyMaterial>>> call({String? subjectId});
}

class GetStudyMaterialsUseCase implements GetStudyMaterialsUseCaseContract {
  const GetStudyMaterialsUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<List<StudyMaterial>>> call({String? subjectId}) =>
      _repository.getMaterials(subjectId: subjectId);
}
