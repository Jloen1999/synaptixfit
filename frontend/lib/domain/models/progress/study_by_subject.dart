import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_by_subject.freezed.dart';

/// Estudio por asignatura de las últimas semanas (lo calcula el servidor).
@freezed
abstract class StudyBySubject with _$StudyBySubject {
  const factory StudyBySubject({
    required DateTime firstWeek,
    required int weeks,
    @Default(<SubjectStudy>[]) List<SubjectStudy> subjects,
  }) = _StudyBySubject;
}

/// Una asignatura: minutos por semana (de la más antigua a la actual) y cómo
/// van sus repasos. [subjectId] nulo = lo estudiado sin asignatura; [name]
/// nulo con id = asignatura archivada.
@freezed
abstract class SubjectStudy with _$SubjectStudy {
  const factory SubjectStudy({
    String? subjectId,
    String? name,
    required int totalMinutes,
    @Default(<int>[]) List<int> minutesByWeek,
    required int reviews,

    /// Repasos superados (calidad 3 o más), de 0 a 1; nulo sin repasos.
    double? recallRate,

    /// Pocos aciertos en los repasos: conviene repasarla más a menudo.
    @Default(false) bool weak,
  }) = _SubjectStudy;
}
