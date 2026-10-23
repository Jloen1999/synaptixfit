import 'package:dio/dio.dart';

import '../../../domain/models/admin/admin_page.dart';
import '../api/api_client.dart';
import 'dto/admin_json.dart';
import 'dto/audit_entry_dto.dart';

/// Moderación de contenido social (`/api/v1/admin/social/**`).
class AdminModerationRemoteDataSource {
  AdminModerationRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/admin/social';

  Future<AdminPage<ReportedContentDto>> reports({
    String? type,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/reports',
      queryParameters: {'type': ?type, 'page': page, 'size': size},
    );
    return AdminJson.page(response.data!, ReportedContentDto.fromJson);
  }

  Future<void> dismissPostReport(String postId) =>
      _dio.post<void>('$_base/posts/$postId/dismiss-report');

  Future<void> dismissCommentReport(String commentId) =>
      _dio.post<void>('$_base/comments/$commentId/dismiss-report');

  Future<void> removePost(String postId) =>
      _dio.delete<void>('$_base/posts/$postId');

  Future<void> removeComment(String commentId) =>
      _dio.delete<void>('$_base/comments/$commentId');
}
