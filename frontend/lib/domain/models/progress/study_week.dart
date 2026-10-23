import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_week.freezed.dart';

/// «Tu estudio» de la semana en curso, tal como lo calcula el servidor:
/// concentración, bloques de estudio, repasos y simulacros.
@freezed
abstract class StudyWeek with _$StudyWeek {
  const factory StudyWeek({
    required DateTime weekStart,
    @Default(0) int focusMinutes,
    @Default(0) int focusSessions,
    @Default(0) int studyBlocksPlanned,
    @Default(0) int studyBlocksCompleted,

    /// % de bloques hechos; nulo si no se planificó ninguno.
    int? planAdherence,
    @Default(0) int reviewsCompleted,
    @Default(0) int testsCompleted,

    /// Nota media de los simulacros (0-100); nula sin simulacros.
    int? averageTestScore,
    @Default(0) int reviewsDue,

    /// Aún no hay nada que contar esta semana.
    @Default(true) bool empty,
  }) = _StudyWeek;
}
