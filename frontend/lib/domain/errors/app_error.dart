import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Error de dominio que ve la aplicación.
///
/// Las variantes transversales cubren los `code` comunes del catálogo
/// (`docs/03-api/errors.md`). Los `code` de negocio de cada módulo llegan como
/// [AppError.business] y la presentación los traduce por `code`.
@freezed
sealed class AppError with _$AppError {
  /// INTERNAL_ERROR
  const factory AppError.server() = ServerError;

  /// VALIDATION_ERROR (con los campos que fallan)
  const factory AppError.validation({
    @Default(<FieldError>[]) List<FieldError> fields,
  }) = ValidationError;

  /// UNAUTHORIZED
  const factory AppError.unauthorized() = UnauthorizedError;

  /// FORBIDDEN
  const factory AppError.forbidden() = ForbiddenError;

  /// NOT_FOUND
  const factory AppError.notFound() = NotFoundError;

  /// CONFLICT
  const factory AppError.conflict() = ConflictError;

  /// NETWORK_UNAVAILABLE (origen: cliente)
  const factory AppError.network() = NetworkError;

  /// Cualquier `code` de negocio del catálogo (por ejemplo AUTH_INVALID_CREDENTIALS).
  const factory AppError.business(String code) = BusinessError;

  /// UNKNOWN (origen: cliente)
  const factory AppError.unknown() = UnknownAppError;
}

/// Campo concreto que no supera la validación.
@freezed
abstract class FieldError with _$FieldError {
  const factory FieldError({required String field, required String code}) =
      _FieldError;
}
