part of 'test_results_bloc.dart';

@freezed
abstract class TestResultsState with _$TestResultsState {
  const factory TestResultsState({
    @Default('') String sessionId,
    @Default(true) bool loading,
    AppError? error,
    TestSession? session,

    /// Asignatura del apunte del simulacro (nula si no se pudo leer).
    String? subjectId,
  }) = _TestResultsState;
}
