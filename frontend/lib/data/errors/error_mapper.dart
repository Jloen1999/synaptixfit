import '../../domain/errors/app_error.dart';
import 'custom_error.dart';
import 'generic_error.dart';
import 'http_errors/http_error.dart';
import 'unknown_error.dart';

/// Traduce [GenericError] a [AppError] **por `code`**, nunca por estado HTTP.
abstract final class ErrorMapper {
  static AppError mapToError(GenericError error) => switch (error) {
    HttpError(:final code, :final fields) => fromCode(
      code,
      fields.map((f) => FieldError(field: f.field, code: f.code)).toList(),
    ),
    CustomError(:final code) => fromCode(code),
    UnknownError() => const AppError.unknown(),
    _ => const AppError.unknown(),
  };

  static AppError fromCode(String code, [List<FieldError> fields = const []]) =>
      switch (code) {
        'INTERNAL_ERROR' => const AppError.server(),
        'VALIDATION_ERROR' ||
        'BAD_REQUEST' => AppError.validation(fields: fields),
        'UNAUTHORIZED' => const AppError.unauthorized(),
        'FORBIDDEN' => const AppError.forbidden(),
        'NOT_FOUND' => const AppError.notFound(),
        'CONFLICT' => const AppError.conflict(),
        'NETWORK_UNAVAILABLE' => const AppError.network(),
        'UNKNOWN' || 'METHOD_NOT_ALLOWED' => const AppError.unknown(),
        _ => AppError.business(code),
      };
}
