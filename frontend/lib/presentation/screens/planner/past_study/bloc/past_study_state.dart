part of 'past_study_bloc.dart';

@freezed
abstract class PastStudyState with _$PastStudyState {
  const factory PastStudyState({
    @Default(false) bool loadingSubjects,
    @Default(<SubjectOption>[]) List<SubjectOption> subjects,

    /// No se pudieron leer las asignaturas (se puede apuntar sin ninguna).
    @Default(false) bool subjectsFailed,
    @Default(false) bool submitting,

    /// Guardado: XP ganada (0 si se pasó del tope diario). La página cierra.
    int? savedXp,
    Account? updatedAccount,
    AppError? error,
  }) = _PastStudyState;
}
