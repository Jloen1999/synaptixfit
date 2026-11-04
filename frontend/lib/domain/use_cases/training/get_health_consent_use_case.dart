import '../../models/result/app_result.dart';
import '../../models/training/health_consent.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Si la persona ha dado el permiso para guardar su registro diario.
abstract interface class GetHealthConsentUseCaseContract {
  Future<AppResult<HealthConsent>> call();
}

class GetHealthConsentUseCase implements GetHealthConsentUseCaseContract {
  const GetHealthConsentUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<HealthConsent>> call() => _repository.getHealthConsent();
}
