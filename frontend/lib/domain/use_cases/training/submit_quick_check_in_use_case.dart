import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/today_adaptation.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Registro rápido de tres toques (sueño, energía y agujetas).
abstract interface class SubmitQuickCheckInUseCaseContract {
  Future<AppResult<Unit>> call(QuickCheckIn input);
}

class SubmitQuickCheckInUseCase implements SubmitQuickCheckInUseCaseContract {
  const SubmitQuickCheckInUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call(QuickCheckIn input) =>
      _repository.submitQuickCheckIn(input);
}
