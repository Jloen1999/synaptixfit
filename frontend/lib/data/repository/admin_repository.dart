import 'dart:convert';

import '../../domain/enums/user_role.dart';
import '../../domain/models/admin/admin_page.dart';
import '../../domain/models/admin/admin_queries.dart';
import '../../domain/models/admin/admin_user.dart';
import '../../domain/models/admin/admin_user_stats.dart';
import '../../domain/models/admin/audit_entry.dart';
import '../../domain/models/admin/erasure_report.dart';
import '../../domain/models/admin/lockdown_status.dart';
import '../../domain/models/admin/platform_metrics.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/repositories/admin_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/admin/admin_remote_data_source.dart';

class AdminRepository implements AdminRepositoryContract {
  AdminRepository(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<AppResult<PlatformMetrics>> getMetrics() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.metrics()).toDomain(),
      );

  @override
  Future<AppResult<List<DailyActivity>>> getActivityTrend({
    required int days,
  }) => RepositoryErrorHandler.guard(
    () async => [for (final d in await _remote.trend(days)) d.toDomain()],
  );

  @override
  Future<AppResult<LockdownStatus>> getLockdown() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.lockdown()).toDomain(),
      );

  @override
  Future<AppResult<LockdownStatus>> setLockdown({required bool active}) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.setLockdown(active)).toDomain(),
      );

  @override
  Future<AppResult<AdminPage<AdminUserSummary>>> searchUsers({
    required AdminUserQuery query,
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(() async {
    final text = query.text.trim();
    final result = await _remote.users({
      if (text.isNotEmpty) 'query': text,
      if (query.role != null)
        'role': query.role == UserRole.admin ? 'ADMIN' : 'USER',
      'shadowbanned': ?query.shadowbanned,
      'status': query.status.apiValue,
      'minLevel': ?query.minLevel,
      'maxLevel': ?query.maxLevel,
      'sort': query.sort.apiValue,
      'direction': query.direction.apiValue,
      'page': page,
      'size': size,
    });
    return _mapPage(result, (dto) => dto.toDomain());
  });

  @override
  Future<AppResult<AdminUserDetail>> getUserDetail(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.userDetail(userId)).toDomain(),
      );

  @override
  Future<AppResult<AdminUserStats>> getUserStats(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.userStats(userId)).toDomain(),
      );

  @override
  Future<AppResult<List<AdminWeeklyActivity>>> getUserActivity(
    String userId, {
    required int weeks,
  }) => RepositoryErrorHandler.guard(
    () async => [
      for (final w in await _remote.userActivity(userId, weeks)) w.toDomain(),
    ],
  );

  @override
  Future<AppResult<AdminPage<AdminTimelineEntry>>> getUserTimeline(
    String userId, {
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(
    () async => _mapPage(
      await _remote.userTimeline(userId, page, size),
      (dto) => dto.toDomain(),
    ),
  );

  @override
  Future<AppResult<AdminUserAccount>> updateUserIdentity(
    String userId, {
    String? fullName,
    String? email,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.updateIdentity(userId, {
      'fullName': ?fullName,
      'email': ?email,
    })).toDomain(),
  );

  @override
  Future<AppResult<AdminUserAccount>> setUserProgress(
    String userId, {
    required int level,
    required int levelXp,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setProgress(userId, level, levelXp)).toDomain(),
  );

  @override
  Future<AppResult<AdminUserAccount>> changeUserRole(
    String userId,
    UserRole role,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.changeRole(
      userId,
      role == UserRole.admin ? 'ADMIN' : 'USER',
    )).toDomain(),
  );

  @override
  Future<AppResult<AdminUserAccount>> setUserShadowban(
    String userId, {
    required bool shadowbanned,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setShadowban(userId, shadowbanned)).toDomain(),
  );

  @override
  Future<AppResult<ErasureReport>> wipeUser(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.wipe(userId)).toDomain(),
      );

  @override
  Future<AppResult<ErasureReport>> anonymizeUser(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.anonymize(userId)).toDomain(),
      );

  @override
  Future<AppResult<ErasureReport>> deleteUser(String userId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.delete(userId)).toDomain(),
      );

  @override
  Future<AppResult<String>> exportUserData(String userId) =>
      RepositoryErrorHandler.guard(() async {
        final raw = await _remote.export(userId);
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
      });

  @override
  Future<AppResult<AdminPage<AuditEntry>>> searchAudit({
    required AuditQuery query,
    required int page,
    required int size,
  }) => RepositoryErrorHandler.guard(() async {
    final result = await _remote.audit({
      if (query.action != null) 'action': query.action!.apiValue,
      if (query.entityType != null) 'entityType': query.entityType!.apiValue,
      'entityId': ?query.entityId,
      if (query.from != null) 'from': query.from!.toUtc().toIso8601String(),
      if (query.to != null) 'to': query.to!.toUtc().toIso8601String(),
      'page': page,
      'size': size,
    });
    return _mapPage(result, (dto) => dto.toDomain());
  });

  static AdminPage<R> _mapPage<T, R>(AdminPage<T> page, R Function(T) map) =>
      AdminPage<R>(
        items: [for (final item in page.items) map(item)],
        page: page.page,
        size: page.size,
        totalItems: page.totalItems,
        totalPages: page.totalPages,
      );
}
