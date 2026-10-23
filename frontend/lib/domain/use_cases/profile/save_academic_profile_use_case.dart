import '../../models/profile/academic_profile.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Crea o reemplaza el perfil académico.
abstract interface class SaveAcademicProfileUseCaseContract {
  Future<AppResult<AcademicProfile>> call(AcademicProfileDraft draft);
}

class SaveAcademicProfileUseCase implements SaveAcademicProfileUseCaseContract {
  const SaveAcademicProfileUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<AcademicProfile>> call(AcademicProfileDraft draft) =>
      _repository.saveAcademicProfile(draft);
}
