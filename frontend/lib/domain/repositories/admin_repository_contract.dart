import '../enums/user_role.dart';
import '../models/admin/admin_page.dart';
import '../models/admin/admin_queries.dart';
import '../models/admin/admin_user.dart';
import '../models/admin/admin_user_stats.dart';
import '../models/admin/audit_entry.dart';
import '../models/admin/erasure_report.dart';
import '../models/admin/lockdown_status.dart';
import '../models/admin/platform_metrics.dart';
import '../models/result/app_result.dart';

/// Administración de usuarios, métricas, bloqueo global y auditoría
/// (`/api/v1/admin/**`). El backend identifica al administrador por el token.
abstract interface class AdminRepositoryContract {
  Future<AppResult<PlatformMetrics>> getMetrics();

  Future<AppResult<List<DailyActivity>>> getActivityTrend({required int days});

  Future<AppResult<LockdownStatus>> getLockdown();

  Future<AppResult<LockdownStatus>> setLockdown({required bool active});

  Future<AppResult<AdminPage<AdminUserSummary>>> searchUsers({
    required AdminUserQuery query,
    required int page,
    required int size,
  });

  Future<AppResult<AdminUserDetail>> getUserDetail(String userId);

  Future<AppResult<AdminUserStats>> getUserStats(String userId);

  Future<AppResult<List<AdminWeeklyActivity>>> getUserActivity(
    String userId, {
    required int weeks,
  });

  Future<AppResult<AdminPage<AdminTimelineEntry>>> getUserTimeline(
    String userId, {
    required int page,
    required int size,
  });

  /// Los parámetros nulos no cambian.
  Future<AppResult<AdminUserAccount>> updateUserIdentity(
    String userId, {
    String? fullName,
    String? email,
  });

  Future<AppResult<AdminUserAccount>> setUserProgress(
    String userId, {
    required int level,
    required int levelXp,
  });

  Future<AppResult<AdminUserAccount>> changeUserRole(
    String userId,
    UserRole role,
  );

  Future<AppResult<AdminUserAccount>> setUserShadowban(
    String userId, {
    required bool shadowbanned,
  });

  Future<AppResult<ErasureReport>> wipeUser(String userId);

  Future<AppResult<ErasureReport>> anonymizeUser(String userId);

  Future<AppResult<ErasureReport>> deleteUser(String userId);

  /// Exportación RGPD del usuario como texto JSON legible.
  Future<AppResult<String>> exportUserData(String userId);

  Future<AppResult<AdminPage<AuditEntry>>> searchAudit({
    required AuditQuery query,
    required int page,
    required int size,
  });
}
