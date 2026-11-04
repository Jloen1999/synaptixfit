import 'package:dio/dio.dart';

import '../../../domain/enums/legal_document_kind.dart';
import '../api/api_client.dart';
import 'dto/legal_dto.dart';

/// Textos legales (`GET /api/v1/legal/{document}`, públicos) y su aceptación
/// (`/api/v1/me/legal-acceptance`, con sesión). ADR 0034.
class LegalRemoteDataSource {
  LegalRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _acceptance = '/api/v1/me/legal-acceptance';

  Future<LegalDocumentDto> document(
    LegalDocumentKind kind, {
    required String language,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/legal/${kind.slug}',
      queryParameters: {'lang': language},
    );
    return LegalDocumentDto.fromJson(response.data!);
  }

  Future<LegalAcceptanceDto> acceptance() async {
    final response = await _dio.get<Map<String, dynamic>>(_acceptance);
    return LegalAcceptanceDto.fromJson(response.data!);
  }

  Future<void> accept(String version) =>
      _dio.put<void>(_acceptance, data: {'version': version});
}
