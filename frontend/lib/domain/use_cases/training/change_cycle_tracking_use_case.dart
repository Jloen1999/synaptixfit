import '../../models/result/app_result.dart';
import '../../models/training/cycle.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Activa (con consentimiento) o desactiva el seguimiento del ciclo; al
/// desactivarlo puede borrar lo apuntado.
abstract interface class ChangeCycleTrackingUseCaseContract {
  Future<AppResult<CycleOverview>> call({
    required bool enabled,
    bool consent = false,
    bool deleteHistory = false,
  });
}

class ChangeCycleTrackingUseCase implements ChangeCycleTrackingUseCaseContract {
  const ChangeCycleTrackingUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<CycleOverview>> call({
    required bool enabled,
    bool consent = false,
    bool deleteHistory = false,
  }) => _repository.changeCycleTracking(
    enabled: enabled,
    consent: consent,
    deleteHistory: deleteHistory,
  );
}
