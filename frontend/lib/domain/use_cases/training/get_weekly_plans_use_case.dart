import '../../models/result/app_result.dart';
import '../../models/training/training_page.dart';
import '../../models/training/wellbeing.dart';
import '../../repositories/training_repository_contract.dart';

/// Historial de planes semanales.
abstract interface class GetWeeklyPlansUseCaseContract {
  Future<AppResult<TrainingPage<WeeklyPlan>>> call({
    int page = 0,
    int size = 20,
  });
}

class GetWeeklyPlansUseCase implements GetWeeklyPlansUseCaseContract {
  const GetWeeklyPlansUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<WeeklyPlan>>> call({
    int page = 0,
    int size = 20,
  }) => _repository.getWeeklyPlans(page: page, size: size);
}
