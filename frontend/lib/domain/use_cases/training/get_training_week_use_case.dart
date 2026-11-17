import '../../models/result/app_result.dart';
import '../../models/training/training_week.dart';
import '../../repositories/training_repository_contract.dart';

/// La semana de entreno en curso: días entrenados, los que tocan y hoy.
abstract interface class GetTrainingWeekUseCaseContract {
  Future<AppResult<TrainingWeek>> call();
}

class GetTrainingWeekUseCase implements GetTrainingWeekUseCaseContract {
  const GetTrainingWeekUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<TrainingWeek>> call() => _repository.getTrainingWeek();
}
