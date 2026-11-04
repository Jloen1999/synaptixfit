part of 'exercise_guide_bloc.dart';

/// Qué contar tras guardar la nota.
enum ExerciseGuideNotice { saved, deleted, failed }

@freezed
abstract class ExerciseGuideState with _$ExerciseGuideState {
  const factory ExerciseGuideState({
    String? exerciseId,
    @Default(true) bool loading,
    @Default(ExerciseTips()) ExerciseTips tips,
    ExerciseNote? note,

    /// No se pudo leer la nota: se ofrece reintentar en vez de editarla.
    AppError? noteError,
    @Default(false) bool saving,
    AppError? saveError,
    ExerciseGuideNotice? notice,
    @Default(0) int noticeId,
  }) = _ExerciseGuideState;
}
