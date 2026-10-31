import 'package:dio/dio.dart';

import '../../../domain/models/training/training_page.dart';
import '../api/api_client.dart';
import 'dto/page_dto.dart';
import 'dto/session_history_dto.dart';

/// Historial con nombres y récords personales (`/api/v1/training/history`, `/records`).
class TrainingHistoryRemoteDataSource {
  TrainingHistoryRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/training';

  Future<TrainingPage<SessionHistoryDto>> history({
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/history',
      queryParameters: {'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, SessionHistoryDto.fromJson);
  }

  /// Mejor serie de la última sesión de cada ejercicio.
  Future<List<PersonalRecordDto>> lastPerformance() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/training/last-performance',
    );
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PersonalRecordDto.fromJson)
        .toList();
  }

  Future<SessionHighlightsDto> highlights(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/sessions/$sessionId/highlights',
    );
    return SessionHighlightsDto.fromJson(response.data!);
  }

  Future<List<PersonalRecordDto>> records() async {
    final response = await _dio.get<List<dynamic>>('$_base/records');
    return [
      for (final item in response.data ?? const [])
        PersonalRecordDto.fromJson(item as Map<String, dynamic>),
    ];
  }
}
