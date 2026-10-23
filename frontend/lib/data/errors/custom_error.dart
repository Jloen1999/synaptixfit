import 'generic_error.dart';

/// Error originado en el propio cliente con un `code` del catálogo
/// (por ejemplo GOOGLE_SIGN_IN_CANCELLED).
class CustomError implements GenericError {
  const CustomError(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => 'CustomError($code, $detail)';
}
