import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/device_zone.dart';
import 'dto/subject_dtos.dart';

/// Endpoints de asignaturas (`/api/v1/subjects`) y la línea de tiempo filtrada
/// por asignatura (`/api/v1/planner/timeline`).
class SubjectsRemoteDataSource {
  SubjectsRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/subjects';

  Future<List<SubjectDto>> getSubjects({required bool archived}) async {
    final response = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: {'archived': archived, 'zone': deviceZoneOffset()},
    );
    return _list(response.data, SubjectDto.fromJson);
  }

  Future<SubjectDto> getSubject(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$id',
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return SubjectDto.fromJson(response.data!);
  }

  Future<SubjectDto> createSubject(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(_base, data: body);
    return SubjectDto.fromJson(response.data!);
  }

  Future<SubjectDto> updateSubject(String id, Map<String, dynamic> body) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$id',
      data: body,
      queryParameters: {'zone': deviceZoneOffset()},
    );
    return SubjectDto.fromJson(response.data!);
  }

  Future<void> deleteSubject(String id) => _dio.delete<void>('$_base/$id');

  Future<List<SubjectSemesterDto>> getSemesters() async {
    final response = await _dio.get<List<dynamic>>('$_base/semesters');
    return _list(response.data, SubjectSemesterDto.fromJson);
  }

  Future<SubjectSemesterDto> assignSemester(
    String id,
    int course,
    int semester,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$id/semester',
      data: {'course': course, 'semester': semester},
    );
    return SubjectSemesterDto.fromJson(response.data!);
  }

  Future<void> clearSemester(String id) =>
      _dio.delete<void>('$_base/$id/semester');

  Future<RetentionDto> getRetention(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$id/retention',
    );
    return RetentionDto.fromJson(response.data!);
  }

  Future<TeachingGuideDto> getTeachingGuide(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$id/teaching-guide',
    );
    return TeachingGuideDto.fromJson(response.data!);
  }

  Future<TeachingGuideDto> setTeachingGuideMode(String id, String mode) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$id/teaching-guide/mode',
      data: {'mode': mode},
    );
    return TeachingGuideDto.fromJson(response.data!);
  }

  Future<TeachingGuideDto> setTopicCompleted(
    String id,
    int index,
    bool completed,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$id/teaching-guide/topics/$index',
      data: {'completed': completed},
    );
    return TeachingGuideDto.fromJson(response.data!);
  }

  Future<TeachingGuideDto> setAssessmentGrade(
    String id,
    int index,
    double? grade,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$id/teaching-guide/assessments/$index',
      data: {'grade': grade},
    );
    return TeachingGuideDto.fromJson(response.data!);
  }

  Future<List<SubjectTimelineItemDto>> getTimeline(
    String subjectId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/planner/timeline',
      queryParameters: {
        'subjectId': subjectId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    return _list(response.data, SubjectTimelineItemDto.fromJson);
  }
}

List<T> _list<T>(
  List<dynamic>? data,
  T Function(Map<String, dynamic>) fromJson,
) => (data ?? const []).cast<Map<String, dynamic>>().map(fromJson).toList();
