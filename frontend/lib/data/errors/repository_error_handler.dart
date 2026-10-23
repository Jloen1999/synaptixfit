import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/errors/app_error.dart';
import '../../domain/models/result/result.dart';
import 'error_extension.dart';
import 'error_mapper.dart';

/// Único punto donde se capturan excepciones: los repositorios envuelven cada
/// llamada en [guard] o [guardStream] y nunca usan try/catch.
abstract final class RepositoryErrorHandler {
  static Future<Result<T, AppError>> guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } catch (error, stackTrace) {
      final generic = error.toGenericError(stackTrace);
      debugPrint('Repository error: $generic');
      return Failure(ErrorMapper.mapToError(generic));
    }
  }

  static Stream<Result<T, AppError>> guardStream<T>(
    Stream<T> Function() action,
  ) {
    return action().transform(
      StreamTransformer<T, Result<T, AppError>>.fromHandlers(
        handleData: (value, sink) => sink.add(Success(value)),
        handleError: (error, stackTrace, sink) => sink.add(
          Failure(ErrorMapper.mapToError(error.toGenericError(stackTrace))),
        ),
      ),
    );
  }
}
