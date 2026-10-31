import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/notification_preferences_dto.dart';

/// Preferencias de notificaciones (`/api/v1/notifications/preferences`).
class NotificationPreferencesRemoteDataSource {
  NotificationPreferencesRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _path = '/api/v1/notifications/preferences';

  Future<NotificationPreferencesDto> get() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    return NotificationPreferencesDto.fromJson(response.data!);
  }

  static const _weeklyEmail = '/api/v1/notifications/weekly-email';

  /// Estado del resumen semanal por correo: `OFF`, `PENDING` o `ACTIVE`.
  Future<String?> weeklyEmail() async {
    final response = await _dio.get<Map<String, dynamic>>(_weeklyEmail);
    return response.data?['status'] as String?;
  }

  Future<String?> enableWeeklyEmail() async {
    final response = await _dio.put<Map<String, dynamic>>(_weeklyEmail);
    return response.data?['status'] as String?;
  }

  Future<void> disableWeeklyEmail() => _dio.delete<void>(_weeklyEmail);

  Future<NotificationPreferencesDto> update(Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(_path, data: body);
    return NotificationPreferencesDto.fromJson(response.data!);
  }
}
