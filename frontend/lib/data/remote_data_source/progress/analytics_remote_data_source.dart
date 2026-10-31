import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/study_by_subject_dto.dart';
import 'dto/analytics_dto.dart';

/// Endpoints de analítica (`/api/v1/analytics`).
class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<WeeklyAnalyticsDto> weekly(String period) async =>
      WeeklyAnalyticsDto.fromJson(await _get('weekly', {'period': period}));

  Future<TrainingVolumeDto> volume(String period) async =>
      TrainingVolumeDto.fromJson(await _get('volume', {'period': period}));

  Future<RpeTrendDto> rpeTrend(String period) async =>
      RpeTrendDto.fromJson(await _get('rpe-trend', {'period': period}));

  Future<CorrelationDto> correlation(String metric) async =>
      CorrelationDto.fromJson(await _get('correlation', {'metric': metric}));

  Future<StudyWeekDto> studyWeek() async =>
      StudyWeekDto.fromJson(await _get('study-week', const {}));

  Future<StudyBySubjectDto> studyBySubject(int weeks) async =>
      StudyBySubjectDto.fromJson(
        await _get('study-subjects', {'weeks': weeks}),
      );

  Future<List<InsightDto>> insights(String period) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/analytics/insights',
      queryParameters: {'period': period},
    );
    return (response.data ?? const [])
        .map((e) => InsightDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/analytics/$path',
      queryParameters: query,
    );
    return response.data!;
  }
}
