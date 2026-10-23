import '../../models/profile/onboarding_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/profile_repository_contract.dart';

/// Cierra el onboarding (requiere perfil físico).
abstract interface class CompleteOnboardingUseCaseContract {
  Future<AppResult<OnboardingStatus>> call();
}

class CompleteOnboardingUseCase implements CompleteOnboardingUseCaseContract {
  const CompleteOnboardingUseCase(this._repository);

  final ProfileRepositoryContract _repository;

  @override
  Future<AppResult<OnboardingStatus>> call() =>
      _repository.completeOnboarding();
}
