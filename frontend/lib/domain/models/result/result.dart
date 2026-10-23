/// Resultado de una operación: éxito con valor o fallo con error.
///
/// Los casos de uso y repositorios nunca lanzan excepciones: devuelven un [Result].
sealed class Result<T, E> {
  const Result();

  const factory Result.success(T value) = Success<T, E>;
  const factory Result.failure(E error) = Failure<T, E>;

  bool get isSuccess => this is Success<T, E>;

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  R fold<R>(R Function(T value) onSuccess, R Function(E error) onFailure) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure(:final error) => onFailure(error),
      };

  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success<R, E>(transform(value)),
    Failure(:final error) => Failure<R, E>(error),
  };

  Future<Result<R, E>> then<R>(
    Future<Result<R, E>> Function(T value) next,
  ) async => switch (this) {
    Success(:final value) => await next(value),
    Failure(:final error) => Failure<R, E>(error),
  };
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);

  final E error;
}

/// Valor vacío para operaciones sin resultado.
final class Unit {
  const Unit._();
}

const unit = Unit._();
