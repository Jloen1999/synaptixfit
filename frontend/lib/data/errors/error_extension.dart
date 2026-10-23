import 'package:dio/dio.dart';

import 'generic_error.dart';
import 'http_errors/http_error.dart';
import 'unknown_error.dart';

extension ToGenericError on Object {
  /// Clasifica cualquier excepción técnica.
  GenericError toGenericError([StackTrace? stackTrace]) {
    final self = this;
    if (self is GenericError) return self;
    if (self is DioException) {
      final inner = self.error;
      if (inner is GenericError) return inner;
      return HttpError.fromDio(self);
    }
    return UnknownError(self, stackTrace);
  }
}
