import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// Envía el idioma de la app en `Accept-Language`: el servidor lo usa para
/// que la IA escriba en ese idioma. El idioma activo es `Intl.defaultLocale`,
/// que fija la app al resolver su idioma.
class LanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final code = Intl.getCurrentLocale().split(RegExp('[-_]')).first;
    if (code.isNotEmpty) options.headers['Accept-Language'] = code;
    handler.next(options);
  }
}
