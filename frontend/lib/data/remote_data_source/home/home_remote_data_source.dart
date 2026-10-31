import '../../../domain/models/home/home_setup.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/home_dashboard_dto.dart';
import 'dto/home_due_review_dto.dart';

/// Endpoints que usa la pestaña Inicio. El usuario sale del token (no se envía `userId`).
class HomeRemoteDataSource {
  HomeRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<HomeDashboardDto> dashboard() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/dashboard');
    return HomeDashboardDto.fromJson(response.data!);
  }

  Future<List<HomeDueReviewDto>> dueReviews(int limit) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/study-materials/due',
      queryParameters: {'limit': limit},
    );
    return _list(response.data, HomeDueReviewDto.fromJson);
  }

  Future<int> unreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/notifications/unread-count',
    );
    return (response.data?['total'] as num?)?.toInt() ?? 0;
  }

  /// Si la respuesta no trae el campo, se asume completado (no se bloquea al usuario).
  Future<bool> onboardingCompleted() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/profile/onboarding',
    );
    return response.data?['completed'] as bool? ?? true;
  }

  /// Configuración pendiente; las tareas desconocidas se ignoran.
  Future<HomeSetup> setup() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/profile/setup',
    );
    final data = response.data ?? const <String, dynamic>{};
    return HomeSetup(
      pending: [
        for (final code in data['pending'] as List<dynamic>? ?? const [])
          ?HomeSetupTask.fromApi(code as String?),
      ],
      total: (data['total'] as num?)?.toInt() ?? 0,
    );
  }

  static List<T> _list<T>(
    Object? data,
    T Function(Map<String, dynamic>) fromJson,
  ) => (data as List<dynamic>? ?? const [])
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();
}
