import '../../models/home/home_onboarding_status.dart';
import '../../models/result/app_result.dart';
import '../../repositories/home_repository_contract.dart';

abstract interface class GetHomeOnboardingStatusUseCaseContract {
  Future<AppResult<HomeOnboardingStatus>> call();
}

class GetHomeOnboardingStatusUseCase
    implements GetHomeOnboardingStatusUseCaseContract {
  const GetHomeOnboardingStatusUseCase(this._repository);

  final HomeRepositoryContract _repository;

  @override
  Future<AppResult<HomeOnboardingStatus>> call() =>
      _repository.getOnboardingStatus();
}
