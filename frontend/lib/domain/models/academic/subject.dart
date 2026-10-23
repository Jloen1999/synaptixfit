import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/subject_priority.dart';

part 'subject.freezed.dart';

/// Asignatura del usuario.
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
    required bool archived,
    String? catalogSubjectId,
    DateTime? createdAt,
    required int noteCount,
    required int fileCount,
  }) = _Subject;
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
