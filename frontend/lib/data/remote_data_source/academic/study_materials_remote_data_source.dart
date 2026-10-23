import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/material_dtos.dart';

/// Endpoints de materiales de estudio y repaso espaciado
/// (`/api/v1/study-materials`).
class StudyMaterialsRemoteDataSource {
  StudyMaterialsRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/study-materials';

  Future<StudyMaterialDto> register(String originType, String originId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _base,
      data: {'originType': originType, 'originId': originId},
    );
    return StudyMaterialDto.fromJson(response.data!);
  }

  Future<List<StudyMaterialDto>> getMaterials({String? subjectId}) async {
    final response = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: {'subjectId': ?subjectId},
    );
    return _materials(response.data);
  }

  Future<List<StudyMaterialDto>> getDue(int limit) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/due',
      queryParameters: {'limit': limit},
    );
    return _materials(response.data);
  }

  Future<StudyMaterialDto> getMaterial(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/$id');
    return StudyMaterialDto.fromJson(response.data!);
  }

  Future<void> deleteMaterial(String id) => _dio.delete<void>('$_base/$id');

  Future<ReviewPreviewDto> getPreview(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$id/review-preview',
    );
    return ReviewPreviewDto.fromJson(response.data!);
  }

  Future<ReviewResponseDto> review(String id, int quality) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$id/reviews',
      data: {'quality': quality},
    );
    return ReviewResponseDto.fromJson(response.data!);
  }

  Future<List<ReviewRecordDto>> getHistory(String id) async {
    final response = await _dio.get<List<dynamic>>('$_base/$id/reviews');
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ReviewRecordDto.fromJson)
        .toList();
  }

  List<StudyMaterialDto> _materials(List<dynamic>? data) => (data ?? const [])
      .cast<Map<String, dynamic>>()
      .map(StudyMaterialDto.fromJson)
      .toList();
}
