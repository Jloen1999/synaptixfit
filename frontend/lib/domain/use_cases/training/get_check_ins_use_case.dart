import '../../models/result/app_result.dart';
import '../../models/training/training_page.dart';
import '../../models/training/wellbeing.dart';
import '../../repositories/training_repository_contract.dart';

/// Historial de check-ins.
abstract interface class GetCheckInsUseCaseContract {
  Future<AppResult<TrainingPage<CheckIn>>> call({int page = 0, int size = 20});
}

class GetCheckInsUseCase implements GetCheckInsUseCaseContract {
  const GetCheckInsUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingPage<CheckIn>>> call({
    int page = 0,
    int size = 20,
  }) => _repository.getCheckIns(page: page, size: size);
}
