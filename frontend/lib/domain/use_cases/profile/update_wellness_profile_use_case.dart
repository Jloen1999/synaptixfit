import '../../models/profile/wellness_profile.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Edita el perfil físico conservando los campos no enviados.
abstract interface class UpdateWellnessProfileUseCaseContract {
  Future<AppResult<WellnessProfile>> call(WellnessProfileDraft draft);
}

class UpdateWellnessProfileUseCase
    implements UpdateWellnessProfileUseCaseContract {
  const UpdateWellnessProfileUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<WellnessProfile>> call(WellnessProfileDraft draft) =>
      _repository.updateWellnessProfile(draft);
}
