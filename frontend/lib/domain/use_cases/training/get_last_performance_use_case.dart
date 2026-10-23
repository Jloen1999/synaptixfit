import '../../models/result/app_result.dart';
import '../../models/training/session_history.dart';
import '../../repositories/training_history_repository_contract.dart';

/// Lo que hizo la última vez en cada ejercicio («40 kg × 8»).
abstract interface class GetLastPerformanceUseCaseContract {
  Future<AppResult<List<PersonalRecord>>> call();
}

class GetLastPerformanceUseCase implements GetLastPerformanceUseCaseContract {
  const GetLastPerformanceUseCase(this._repository);

  final TrainingHistoryRepositoryContract _repository;

  @override
  Future<AppResult<List<PersonalRecord>>> call() =>
      _repository.getLastPerformance();
}
