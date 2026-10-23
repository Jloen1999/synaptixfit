import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/notification_dto.dart';
import 'dto/page_dto.dart';

/// Endpoints de notificaciones in-app (`/api/v1/notifications`).
class NotificationRemoteDataSource {
  NotificationRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/notifications';

  Future<PageDto<NotificationDto>> list({
    required bool unreadOnly,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {'unreadOnly': unreadOnly, 'page': page, 'size': size},
    );
    return PageDto.fromJson(
      response.data!,
      (json) => NotificationDto.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<int> unreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/unread-count',
    );
    return (response.data!['total'] as num?)?.toInt() ?? 0;
  }

  Future<NotificationDto> markRead(String notificationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$notificationId/read',
    );
    return NotificationDto.fromJson(response.data!);
  }

  Future<int> markAllRead() async {
    final response = await _dio.post<Map<String, dynamic>>('$_base/read-all');
    return (response.data!['updated'] as num?)?.toInt() ?? 0;
  }

  Future<void> delete(String notificationId) =>
      _dio.delete<void>('$_base/$notificationId');
}
