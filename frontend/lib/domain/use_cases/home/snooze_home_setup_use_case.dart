import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../repositories/setup_reminder_repository_contract.dart';

/// «Ahora no» en el aviso de configuración: no se vuelve a mostrar en
/// [snoozeDays] días (lo bastante para no molestar y para no olvidarlo).
abstract interface class SnoozeHomeSetupUseCaseContract {
  /// Devuelve hasta cuándo queda oculto.
  Future<AppResult<DateTime>> call(DateTime now, {required String userId});
}

class SnoozeHomeSetupUseCase implements SnoozeHomeSetupUseCaseContract {
  const SnoozeHomeSetupUseCase(this._reminders);

  static const snoozeDays = 7;

  final SetupReminderRepositoryContract _reminders;

  /// Mismo reloj de pared [snoozeDays] días después (aunque cambie la hora).
  static DateTime untilFrom(DateTime now) =>
      DateTime(now.year, now.month, now.day + snoozeDays, now.hour, now.minute);

  @override
  Future<AppResult<DateTime>> call(
    DateTime now, {
    required String userId,
  }) async {
    final until = untilFrom(now);
    final saved = await _reminders.snoozeUntil(userId, until);
    return saved.fold((_) => Success(until), (error) => Failure(error));
  }
}
