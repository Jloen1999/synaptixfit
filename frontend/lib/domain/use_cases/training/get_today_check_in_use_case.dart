import '../../models/result/app_result.dart';
import '../../models/training/wellbeing.dart';
import '../../repositories/training_repository_contract.dart';

/// Check-in de hoy (o null si no se ha hecho).
abstract interface class GetTodayCheckInUseCaseContract {
  Future<AppResult<CheckIn?>> call();
}

class GetTodayCheckInUseCase implements GetTodayCheckInUseCaseContract {
  const GetTodayCheckInUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<CheckIn?>> call() => _repository.getTodayCheckIn();
}
