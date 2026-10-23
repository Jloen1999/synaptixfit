import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/catalog_dto.dart';

/// Catálogo académico (`/api/v1/catalog/**`) y alta de asignaturas desde él.
class ProfileCatalogRemoteDataSource {
  ProfileCatalogRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<UniversityDto>> universities(String? query) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/catalog/universities',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    return response.data!
        .map((e) => UniversityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DegreeDto>> degrees(String universityId, String? query) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/catalog/universities/$universityId/degrees',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    return response.data!
        .map((e) => DegreeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve cuántas asignaturas creó el backend.
  Future<int> createSubjectsFromCatalog(List<String> catalogSubjectIds) async {
    final response = await _dio.post<List<dynamic>>(
      '/api/v1/subjects/from-catalog',
      data: {'catalogSubjectIds': catalogSubjectIds},
    );
    return response.data?.length ?? 0;
  }
}
