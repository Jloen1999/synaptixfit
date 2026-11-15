part of 'shared_routine_bloc.dart';

enum SharedRoutineStatus { loading, ready, failure }

@freezed
abstract class SharedRoutineState with _$SharedRoutineState {
  const factory SharedRoutineState({
    @Default('') String token,
    @Default(SharedRoutineStatus.loading) SharedRoutineStatus status,
    SharedRoutinePreview? preview,
    AppError? error,
    @Default(false) bool copying,

    /// Copia recién creada (efecto de un solo uso: abrirla).
    Routine? copied,
    AppError? copyError,
  }) = _SharedRoutineState;
}
