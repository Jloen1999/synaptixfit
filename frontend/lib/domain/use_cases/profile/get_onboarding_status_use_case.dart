import '../../models/profile/onboarding_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Pasos pendientes del onboarding.
abstract interface class GetOnboardingStatusUseCaseContract {
  Future<AppResult<OnboardingStatus>> call();
}

class GetOnboardingStatusUseCase implements GetOnboardingStatusUseCaseContract {
  const GetOnboardingStatusUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<OnboardingStatus>> call() =>
      _repository.getOnboardingStatus();
}
