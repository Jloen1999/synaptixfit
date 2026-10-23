import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Preferencia local «recordatorios activados en este dispositivo». Es del
/// teléfono, no de la cuenta: cada dispositivo decide si quiere avisos.
abstract interface class ReminderSettingsRepositoryContract {
  Future<AppResult<bool>> isEnabled();

  Future<AppResult<Unit>> setEnabled(bool enabled);

  /// Emite el nuevo valor cada vez que cambia.
  Stream<bool> watchEnabled();
}
