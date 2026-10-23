import 'package:dio/dio.dart';

import '../../../domain/models/admin/admin_page.dart';
import '../api/api_client.dart';
import 'dto/admin_json.dart';
import 'dto/admin_user_dto.dart';
import 'dto/admin_user_stats_dto.dart';
import 'dto/audit_entry_dto.dart';
import 'dto/platform_metrics_dto.dart';

/// Endpoints de administración de usuarios, métricas, bloqueo y auditoría
/// (`/api/v1/admin/**`). El `adminId` lo resuelve el backend desde el token.
class AdminRemoteDataSource {
  AdminRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/admin';

  Future<PlatformMetricsDto> metrics() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/metrics');
    return PlatformMetricsDto.fromJson(response.data!);
  }

  Future<List<DailyActivityDto>> trend(int days) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/metrics/trend',
      queryParameters: {'days': days},
    );
    return _list(response.data, DailyActivityDto.fromJson);
  }

  Future<LockdownDto> lockdown() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/lockdown');
    return LockdownDto.fromJson(response.data!);
  }

  Future<LockdownDto> setLockdown(bool active) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/lockdown',
      data: {'active': active},
    );
    return LockdownDto.fromJson(response.data!);
  }

  Future<AdminPage<AdminUserSummaryDto>> users(
    Map<String, dynamic> query,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/users',
      queryParameters: query,
    );
    return AdminJson.page(response.data!, AdminUserSummaryDto.fromJson);
  }

  Future<AdminUserDetailDto> userDetail(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/users/$userId',
    );
    return AdminUserDetailDto.fromJson(response.data!);
  }

  Future<AdminUserStatsDto> userStats(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/users/$userId/stats',
    );
    return AdminUserStatsDto.fromJson(response.data!);
  }

  Future<List<AdminWeeklyActivityDto>> userActivity(
    String userId,
    int weeks,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/users/$userId/activity',
      queryParameters: {'weeks': weeks},
    );
    return _list(response.data, AdminWeeklyActivityDto.fromJson);
  }

  Future<AdminPage<AdminTimelineEntryDto>> userTimeline(
    String userId,
    int page,
    int size,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/users/$userId/timeline',
      queryParameters: {'page': page, 'size': size},
    );
    return AdminJson.page(response.data!, AdminTimelineEntryDto.fromJson);
  }

  Future<AdminUserAccountDto> updateIdentity(
    String userId,
    Map<String, dynamic> changes,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/users/$userId',
      data: changes,
    );
    return AdminUserAccountDto.fromJson(response.data!);
  }

  Future<AdminUserAccountDto> setProgress(
    String userId,
    int level,
    int levelXp,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/users/$userId/progress',
      data: {'level': level, 'levelXp': levelXp},
    );
    return AdminUserAccountDto.fromJson(response.data!);
  }

  Future<AdminUserAccountDto> changeRole(String userId, String role) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/users/$userId/role',
      data: {'role': role},
    );
    return AdminUserAccountDto.fromJson(response.data!);
  }

  Future<AdminUserAccountDto> setShadowban(
    String userId,
    bool shadowbanned,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/users/$userId/shadowban',
      data: {'shadowbanned': shadowbanned},
    );
    return AdminUserAccountDto.fromJson(response.data!);
  }

  Future<ErasureReportDto> wipe(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/users/$userId/wipe',
    );
    return ErasureReportDto.fromJson(response.data!);
  }

  Future<ErasureReportDto> anonymize(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/users/$userId/anonymize',
    );
    return ErasureReportDto.fromJson(response.data!);
  }

  Future<ErasureReportDto> delete(String userId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '$_base/users/$userId',
    );
    return ErasureReportDto.fromJson(response.data!);
  }

  /// Devuelve el JSON de exportación tal cual lo envía el servidor.
  Future<String> export(String userId) async {
    final response = await _dio.get<String>(
      '$_base/users/$userId/export',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Future<AdminPage<AuditEntryDto>> audit(Map<String, dynamic> query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/audit',
      queryParameters: query,
    );
    return AdminJson.page(response.data!, AuditEntryDto.fromJson);
  }

  static List<T> _list<T>(
    List<dynamic>? data,
    T Function(Map<String, dynamic>) parse,
  ) => (data ?? const []).cast<Map<String, dynamic>>().map(parse).toList();
}
