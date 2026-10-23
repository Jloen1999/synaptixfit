import '../../models/profile/wellness_profile.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Crea o reemplaza el perfil físico.
abstract interface class SaveWellnessProfileUseCaseContract {
  Future<AppResult<WellnessProfile>> call(WellnessProfileDraft draft);
}

class SaveWellnessProfileUseCase implements SaveWellnessProfileUseCaseContract {
  const SaveWellnessProfileUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<WellnessProfile>> call(WellnessProfileDraft draft) =>
      _repository.saveWellnessProfile(draft);
}
