import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/community_post_dto.dart';
import 'dto/physical_load_dto.dart';

/// Endpoints de otros dominios que usa la pestaña Progreso.
class ProgressRemoteDataSource {
  ProgressRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<PhysicalLoadDto> physicalLoad() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/insights/physical-load',
    );
    return PhysicalLoadDto.fromJson(response.data!);
  }

  Future<CommunityPostPageDto> latestPosts(int size) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/social/posts',
      queryParameters: {'size': size, 'page': 0},
    );
    return CommunityPostPageDto.fromJson(response.data!);
  }

  Future<void> createPost(Map<String, dynamic> body) =>
      _dio.post<void>('/api/v1/social/posts', data: body);
}
