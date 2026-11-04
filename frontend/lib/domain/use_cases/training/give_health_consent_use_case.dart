import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/wellbeing_repository_contract.dart';

/// Da el permiso expreso para guardar el registro diario (datos de salud).
abstract interface class GiveHealthConsentUseCaseContract {
  Future<AppResult<Unit>> call();
}

class GiveHealthConsentUseCase implements GiveHealthConsentUseCaseContract {
  const GiveHealthConsentUseCase(this._repository);

  final WellbeingRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.giveHealthConsent();
}
