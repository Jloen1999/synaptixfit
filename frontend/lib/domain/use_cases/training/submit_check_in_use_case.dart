import '../../models/result/app_result.dart';
import '../../models/training/wellbeing.dart';
import '../../repositories/training_repository_contract.dart';

/// Crea o actualiza el check-in de hoy.
abstract interface class SubmitCheckInUseCaseContract {
  Future<AppResult<CheckInResult>> call(CheckInInput input);
}

class SubmitCheckInUseCase implements SubmitCheckInUseCaseContract {
  const SubmitCheckInUseCase(this._repository);

  final TrainingRepositoryContract _repository;

  @override
  Future<AppResult<CheckInResult>> call(CheckInInput input) =>
      _repository.submitCheckIn(input);
}
