import 'package:dio/dio.dart';

import '../../local_data_source/token_storage.dart';
import 'session_expiry_notifier.dart';

/// Añade el token de acceso y, ante un 401, renueva la sesión una vez y repite
/// la petición. Si no puede renovarla, borra los tokens y avisa.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._dio,
    required this._refreshDio,
    required this._tokens,
    required this._expiry,
  });

  static const _retriedFlag = 'sfx_retried';
  static const _publicPrefix = '/api/v1/auth/';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokens;
  final SessionExpiryNotifier _expiry;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.startsWith(_publicPrefix)) {
      final tokens = await _tokens.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401;
    if (!unauthorized ||
        request.path.startsWith(_publicPrefix) ||
        request.extra[_retriedFlag] == true) {
      return handler.next(err);
    }
    final current = await _tokens.read();
    if (current == null) {
      return handler.next(err);
    }
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final body = response.data!;
      await _tokens.write((
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
      ));
      request.extra[_retriedFlag] = true;
      request.headers['Authorization'] = 'Bearer ${body['accessToken']}';
      final retried = await _dio.fetch<dynamic>(request);
      return handler.resolve(retried);
    } on DioException {
      await _tokens.clear();
      _expiry.notify();
      return handler.next(err);
    }
  }
}
