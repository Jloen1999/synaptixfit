import '../../models/result/app_result.dart';
import '../../repositories/session_clock_intro_repository_contract.dart';

/// Dice si se pidió no volver a explicar el cronómetro al empezar una sesión
/// («No volver a explicarlo»).
abstract interface class GetSessionClockIntroHiddenUseCaseContract {
  Future<AppResult<bool>> call();
}

class GetSessionClockIntroHiddenUseCase
    implements GetSessionClockIntroHiddenUseCaseContract {
  const GetSessionClockIntroHiddenUseCase(this._repository);

  final SessionClockIntroRepositoryContract _repository;

  @override
  Future<AppResult<bool>> call() => _repository.isHidden();
}
