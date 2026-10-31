import '../../models/home/home_setup.dart';
import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/home_repository_contract.dart';
import '../../repositories/setup_reminder_repository_contract.dart';

/// Configuración pendiente del servidor junto con el «Ahora no» guardado en
/// este dispositivo (si no se puede leer, el aviso se muestra).
abstract interface class GetHomeSetupUseCaseContract {
  Future<AppResult<HomeSetup>> call({required String userId});
}

class GetHomeSetupUseCase implements GetHomeSetupUseCaseContract {
  const GetHomeSetupUseCase(this._repository, this._reminders);

  final HomeRepositoryContract _repository;
  final SetupReminderRepositoryContract _reminders;

  @override
  Future<AppResult<HomeSetup>> call({required String userId}) async {
    final result = await _repository.getSetup();
    if (result case Success(value: final setup)) {
      final snoozed = (await _reminders.snoozedUntil(userId)).valueOrNull;
      return Success(setup.copyWith(snoozedUntil: snoozed));
    }
    return result;
  }
}
