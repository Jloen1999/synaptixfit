import 'package:dio/dio.dart';

import '../generic_error.dart';

/// Error de la API HTTP en formato RFC 9457 (`application/problem+json`) con `code`.
class HttpError implements GenericError {
  const HttpError({
    required this.status,
    required this.code,
    this.detail,
    this.fields = const [],
  });

  /// Construye el error a partir de un cuerpo problem+json.
  factory HttpError.fromProblemJson(int status, Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return HttpError(
      status: status,
      code: json['code'] as String? ?? 'UNKNOWN',
      detail: json['detail'] as String?,
      fields: rawFields is List
          ? rawFields
                .whereType<Map<String, dynamic>>()
                .map(
                  (f) => (
                    field: f['field'] as String? ?? '',
                    code: f['code'] as String? ?? 'INVALID',
                  ),
                )
                .toList()
          : const [],
    );
  }

  /// Sin respuesta del servidor (sin conexión, timeout).
  const HttpError.network()
    : status = 0,
      code = 'NETWORK_UNAVAILABLE',
      detail = null,
      fields = const [];

  /// Traduce una excepción de Dio.
  factory HttpError.fromDio(DioException exception) {
    final response = exception.response;
    if (response == null) {
      return const HttpError.network();
    }
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return HttpError.fromProblemJson(response.statusCode ?? 0, data);
    }
    return HttpError(
      status: response.statusCode ?? 0,
      code: (response.statusCode ?? 0) >= 500 ? 'INTERNAL_ERROR' : 'UNKNOWN',
    );
  }

  final int status;
  final String code;

  /// Solo para logs: nunca se muestra al usuario.
  final String? detail;
  final List<({String field, String code})> fields;

  @override
  String toString() => 'HttpError($status, $code, $detail)';
}
