import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/academic_search_dto.dart';

/// Buscador de Académico (`GET /api/v1/academic/search?q=`).
class AcademicSearchRemoteDataSource {
  AcademicSearchRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<AcademicSearchDto> search(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/academic/search',
      queryParameters: {'q': query},
    );
    return AcademicSearchDto.fromJson(response.data!);
  }
}
