import '../enums/guide_id.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Guías ya vistas por cada cuenta en este teléfono (ADR 0049). Es una
/// comodidad del dispositivo, como «Permisos»: no viaja al servidor.
abstract interface class GuideProgressRepositoryContract {
  /// Guías que [accountId] ya ha visto aquí (vacío si ninguna).
  Future<AppResult<Set<GuideId>>> seen(String accountId);

  Future<AppResult<Unit>> markSeen(String accountId, GuideId guide);

  /// Olvida todas las guías vistas de [accountId]: vuelven a salir.
  Future<AppResult<Unit>> reset(String accountId);
}
