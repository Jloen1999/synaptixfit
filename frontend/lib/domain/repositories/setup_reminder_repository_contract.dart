import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Hasta cuándo no se muestra el aviso de configuración pendiente de Inicio
/// (preferencia de este dispositivo, por usuario).
abstract interface class SetupReminderRepositoryContract {
  Future<AppResult<DateTime?>> snoozedUntil(String userId);

  Future<AppResult<Unit>> snoozeUntil(String userId, DateTime until);
}
