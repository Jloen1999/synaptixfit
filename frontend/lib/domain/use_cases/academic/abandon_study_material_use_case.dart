import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Quita un material del repaso sin borrar su historial (queda «abandonado»;
/// repasarlo otra vez lo reactiva).
abstract interface class AbandonStudyMaterialUseCaseContract {
  Future<AppResult<Unit>> call(String materialId);
}

class AbandonStudyMaterialUseCase
    implements AbandonStudyMaterialUseCaseContract {
  const AbandonStudyMaterialUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(String materialId) =>
      _repository.abandonMaterial(materialId);
}
