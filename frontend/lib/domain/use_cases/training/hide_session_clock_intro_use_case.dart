import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/session_clock_intro_repository_contract.dart';

/// Deja de explicar el cronómetro al empezar las sesiones siguientes.
abstract interface class HideSessionClockIntroUseCaseContract {
  Future<AppResult<Unit>> call();
}

class HideSessionClockIntroUseCase
    implements HideSessionClockIntroUseCaseContract {
  const HideSessionClockIntroUseCase(this._repository);

  final SessionClockIntroRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.hide();
}
