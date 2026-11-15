import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/device_zone.dart';
import 'dto/badge_dto.dart';
import 'dto/streak_dto.dart';

/// Endpoints de insignias y racha (`/api/v1/badges`, `/api/v1/streak`).
class BadgeRemoteDataSource {
  BadgeRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<BadgeDto>> catalog({String? category}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/badges',
      queryParameters: {'category': ?category},
    );
    return _badges(response.data);
  }

  Future<List<BadgeDto>> mine({required bool includeHidden}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/badges/mine',
      queryParameters: {'includeHidden': includeHidden},
    );
    return _badges(response.data);
  }

  Future<BadgeDto> changeVisibility(String badgeId, bool visible) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/badges/$badgeId',
      data: {'visible': visible},
    );
    return BadgeDto.fromJson(response.data!);
  }

  /// Obtenidas y aún no celebradas.
  Future<List<BadgeDto>> unnotified() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/badges/unnotified');
    return _badges(response.data);
  }

  Future<void> markNotified(List<String> badgeIds) =>
      _dio.post<void>('/api/v1/badges/notified', data: {'badgeIds': badgeIds});

  Future<StreakDto> streak() async {
    // «Hoy» es el del móvil: el mismo día para la racha, su riesgo y sus pausas.
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/streak',
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return StreakDto.fromJson(response.data!);
  }

  /// «Pausar racha» desde hoy, sin motivo (ADR 0042); devuelve la racha ya en
  /// pausa.
  Future<StreakDto> pauseStreak() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/streak/pause',
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return StreakDto.fromJson(response.data!);
  }

  /// «Reanudar»: la pausa acaba ayer.
  Future<StreakDto> resumeStreak() async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/streak/pause',
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return StreakDto.fromJson(response.data!);
  }

  static List<BadgeDto> _badges(List<dynamic>? data) => (data ?? const [])
      .map((e) => BadgeDto.fromJson(e as Map<String, dynamic>))
      .toList();
}
