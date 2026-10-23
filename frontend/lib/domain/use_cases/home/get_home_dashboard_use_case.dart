import '../../models/home/home_dashboard.dart';
import '../../models/result/app_result.dart';
import '../../repositories/home_repository_contract.dart';

abstract interface class GetHomeDashboardUseCaseContract {
  Future<AppResult<HomeDashboard>> call();
}

class GetHomeDashboardUseCase implements GetHomeDashboardUseCaseContract {
  const GetHomeDashboardUseCase(this._repository);

  final HomeRepositoryContract _repository;

  @override
  Future<AppResult<HomeDashboard>> call() => _repository.getDashboard();
}
