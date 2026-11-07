import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/subject_priority.dart';

part 'subject.freezed.dart';

/// Asignatura del usuario con lo próximo que tiene (ADR 0036): la próxima clase
/// y su aula, los días de clase y la próxima entrega o examen, que calcula el
/// servidor con el horario y las entregas del planificador.
@freezed
abstract class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String name,
    String? code,
    String? description,
    required int credits,
    required int perceivedDifficulty,
    required SubjectPriority priority,
    DateTime? nextAssessmentAt,
    String? teacher,

    /// Aula habitual (opcional): la de la próxima clase si el horario no la da.
    String? room,
    required bool archived,
    String? catalogSubjectId,
    DateTime? createdAt,
    required int noteCount,
    required int fileCount,
    DateTime? nextClassAt,
    String? nextClassPlace,

    /// Días con clase en las próximas dos semanas (1 = lunes).
    @Default(<int>[]) List<int> classDays,
    SubjectDeadline? nextDeadline,

    /// Lo que destaca la tarjeta, ya elegido por el servidor (lo urgente
    /// primero); nulo si no hay nada próximo.
    SubjectNextUp? nextUp,
  }) = _Subject;
}

/// Qué es lo próximo de una asignatura.
enum SubjectNextUpKind {
  delivery('DELIVERY'),
  exam('EXAM'),
  classSession('CLASS'),
  assessment('ASSESSMENT');

  const SubjectNextUpKind(this.apiValue);

  final String apiValue;

  static SubjectNextUpKind? fromApi(String? value) =>
      values.where((k) => k.apiValue == value).firstOrNull;
}

/// Lo próximo de la asignatura tal como lo decide el servidor: qué es, cuándo,
/// dónde (solo clases), cuántos días naturales faltan en la zona del móvil y
/// si urge (hoy o mañana). La tarjeta solo lo pinta.
@freezed
abstract class SubjectNextUp with _$SubjectNextUp {
  const factory SubjectNextUp({
    required SubjectNextUpKind kind,
    required DateTime at,
    String? place,
    required int daysLeft,
    required bool urgent,
  }) = _SubjectNextUp;
}

/// Próxima entrega o examen sin hacer de una asignatura.
@freezed
abstract class SubjectDeadline with _$SubjectDeadline {
  const factory SubjectDeadline({
    required String title,
    required DateTime dueAt,
    required bool exam,
  }) = _SubjectDeadline;
}

/// Datos editables de una asignatura (alta y edición).
@freezed
abstract class SubjectInput with _$SubjectInput {
  const factory SubjectInput({
    required String name,
    String? code,
    String? description,
    int? credits,
    int? perceivedDifficulty,
    SubjectPriority? priority,
    String? teacher,
    String? room,
    DateTime? nextAssessmentAt,
  }) = _SubjectInput;
}

/// Curso y semestre asignados a una asignatura.
@freezed
abstract class SubjectSemester with _$SubjectSemester {
  const factory SubjectSemester({
    required String subjectId,
    required int course,
    required int semester,
  }) = _SubjectSemester;
}

/// Retención de una asignatura por estado de dominio de sus materiales.
@freezed
abstract class Retention with _$Retention {
  const factory Retention({
    required int mastered,
    required int inProgress,
    required int needsReview,
    required int notEvaluated,
    required int abandoned,
    required int total,
  }) = _Retention;

  const Retention._();

  /// Proporción de materiales dominados (0-1).
  double get masteredRatio => total == 0 ? 0 : mastered / total;
}
