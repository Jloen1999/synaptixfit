import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/session.dart';

/// Series apuntadas sin conexión que aún no ha recibido el servidor. Se
/// guardan en el teléfono por sesión para no perderlas si se cierra la app.
abstract interface class PendingSetsRepositoryContract {
  Future<AppResult<List<SetRecord>>> load(String sessionId);

  /// Sustituye las pendientes de la sesión; una lista vacía las borra.
  Future<AppResult<Unit>> save(String sessionId, List<SetRecord> sets);
}
