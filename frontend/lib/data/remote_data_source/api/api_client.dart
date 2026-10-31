import 'package:dio/dio.dart';

import '../../local_data_source/token_storage.dart';
import 'auth_interceptor.dart';
import 'data_change_interceptor.dart';
import 'language_interceptor.dart';
import 'session_expiry_notifier.dart';

/// Cliente HTTP de la API de SynaptixFit. Todas las fuentes de datos remotas lo usan.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokens,
    required SessionExpiryNotifier expiry,
    required DataChangeInterceptor changes,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 120),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    dio = Dio(options);
    final refreshDio = Dio(options);
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        tokens: tokens,
        expiry: expiry,
      ),
    );
    dio.interceptors
      ..add(changes)
      ..add(LanguageInterceptor());
  }

  late final Dio dio;
}
