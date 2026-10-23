import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/errors/error_extension.dart';
import 'package:synaptixfit/data/errors/error_mapper.dart';
import 'package:synaptixfit/data/errors/http_errors/http_error.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';

void main() {
  RequestOptions request() => RequestOptions(path: '/x');

  test('traduce por code y no por estado HTTP', () {
    final error = HttpError.fromProblemJson(404, {
      'status': 404,
      'code': 'ROUTINE_NOT_FOUND',
      'detail': 'Routine 1 not found',
    });
    expect(
      ErrorMapper.mapToError(error),
      const AppError.business('ROUTINE_NOT_FOUND'),
    );
  });

  test('VALIDATION_ERROR conserva los campos', () {
    final error = HttpError.fromProblemJson(400, {
      'code': 'VALIDATION_ERROR',
      'fields': [
        {'field': 'email', 'code': 'INVALID_FORMAT'},
      ],
    });
    expect(
      ErrorMapper.mapToError(error),
      const AppError.validation(
        fields: [FieldError(field: 'email', code: 'INVALID_FORMAT')],
      ),
    );
  });

  test('sin respuesta del servidor es NETWORK_UNAVAILABLE', () {
    final exception = DioException(
      requestOptions: request(),
      type: DioExceptionType.connectionError,
    );
    expect(
      ErrorMapper.mapToError(exception.toGenericError()),
      const AppError.network(),
    );
  });

  test('error inesperado es UNKNOWN', () {
    expect(
      ErrorMapper.mapToError(StateError('x').toGenericError()),
      const AppError.unknown(),
    );
  });
}
