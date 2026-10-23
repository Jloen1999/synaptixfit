part of 'degrees_bloc.dart';

enum DegreesStatus { loading, ready, failure }

enum DegreesOutcome { linked, unlinked }

@freezed
abstract class DegreesState with _$DegreesState {
  const factory DegreesState({
    @Default(DegreesStatus.loading) DegreesStatus status,
    @Default(<UserDegree>[]) List<UserDegree> degrees,
    @Default(false) bool busy,

    /// Resultado de la última acción (para el aviso).
    DegreesOutcome? outcome,
    AppError? error,
    AppError? actionError,
  }) = _DegreesState;
}
