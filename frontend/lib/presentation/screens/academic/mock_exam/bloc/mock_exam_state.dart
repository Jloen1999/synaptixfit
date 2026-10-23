part of 'mock_exam_bloc.dart';

@freezed
abstract class MockExamState with _$MockExamState {
  const factory MockExamState({
    @Default(true) bool loading,
    AppError? error,
    TestSession? session,
    @Default(0) int index,
    @Default('') String draft,
    @Default(false) bool submitting,
    @Default(false) bool finishing,
    AppError? actionError,
    Account? updatedAccount,

    /// Sesión terminada: se abren sus resultados.
    String? closedSessionId,
    @Default(false) bool abandoned,
  }) = _MockExamState;

  const MockExamState._();

  SessionQuestion? get current {
    final qs = session?.questions ?? const <SessionQuestion>[];
    return index < qs.length ? qs[index] : null;
  }

  int get total => session?.questions.length ?? 0;

  int get answered => session?.questions.where((q) => q.answered).length ?? 0;

  bool get allAnswered => total > 0 && answered == total;
}
