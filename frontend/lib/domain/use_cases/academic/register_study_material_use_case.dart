import '../../enums/study_source_type.dart';
import '../../models/academic/study_material.dart';
import '../../models/result/app_result.dart';
import '../../repositories/study_material_repository_contract.dart';

/// Registra un apunte o archivo en el repaso espaciado.
abstract interface class RegisterStudyMaterialUseCaseContract {
  Future<AppResult<StudyMaterial>> call(
    StudySourceType originType,
    String originId,
  );
}

class RegisterStudyMaterialUseCase
    implements RegisterStudyMaterialUseCaseContract {
  const RegisterStudyMaterialUseCase(this._repository);

  final StudyMaterialRepositoryContract _repository;

  @override
  Future<AppResult<StudyMaterial>> call(
    StudySourceType originType,
    String originId,
  ) => _repository.registerMaterial(originType, originId);
}
