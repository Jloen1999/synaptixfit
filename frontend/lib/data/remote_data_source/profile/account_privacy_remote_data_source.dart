import 'package:dio/dio.dart';

import '../api/api_client.dart';

/// Exportación del fichero RGPD: contenido JSON y nombre sugerido.
typedef DataExportFile = ({String fileName, String content});

/// Autoservicio RGPD (`GET /api/v1/me/export`, `DELETE /api/v1/me`).
class AccountPrivacyRemoteDataSource {
  AccountPrivacyRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _defaultFileName = 'synaptixfit-mis-datos.json';

  Future<DataExportFile> export() async {
    final response = await _dio.get<String>(
      '/api/v1/me/export',
      options: Options(responseType: ResponseType.plain),
    );
    return (
      fileName:
          _fileNameFrom(response.headers.value('content-disposition')) ??
          _defaultFileName,
      content: response.data ?? '{}',
    );
  }

  Future<void> deleteAccount({String? password, required bool confirm}) =>
      _dio.delete<void>(
        '/api/v1/me',
        data: {'password': ?password, 'confirm': confirm},
      );

  /// Extrae `filename` de la cabecera `Content-Disposition`.
  static String? _fileNameFrom(String? header) {
    if (header == null) return null;
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(header);
    return match?.group(1);
  }
}
