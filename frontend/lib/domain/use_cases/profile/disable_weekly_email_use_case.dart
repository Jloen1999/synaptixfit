import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/notification_preferences_repository_contract.dart';

/// Desactiva el resumen semanal por correo.
abstract interface class DisableWeeklyEmailUseCaseContract {
  Future<AppResult<Unit>> call();
}

class DisableWeeklyEmailUseCase implements DisableWeeklyEmailUseCaseContract {
  const DisableWeeklyEmailUseCase(this._repository);

  final NotificationPreferencesRepositoryContract _repository;

  @override
  Future<AppResult<Unit>> call() => _repository.disableWeeklyEmail();
}
