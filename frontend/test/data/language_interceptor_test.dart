import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:synaptixfit/data/remote_data_source/api/language_interceptor.dart';

class _Handler extends RequestInterceptorHandler {
  RequestOptions? passed;

  @override
  void next(RequestOptions requestOptions) => passed = requestOptions;
}

void main() {
  test('envía el idioma de la app para que la IA escriba en él', () {
    Intl.defaultLocale = 'pt_PT';
    addTearDown(() => Intl.defaultLocale = 'es');
    final handler = _Handler();
    LanguageInterceptor().onRequest(RequestOptions(path: '/x'), handler);
    expect(handler.passed?.headers['Accept-Language'], 'pt');
  });
}
