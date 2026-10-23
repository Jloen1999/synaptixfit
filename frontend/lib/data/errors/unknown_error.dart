import 'generic_error.dart';

/// Error no clasificado.
class UnknownError implements GenericError {
  const UnknownError(this.cause, [this.stackTrace]);

  final Object cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'UnknownError($cause)';
}
