import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/assessment_kind.dart';
import '../../enums/evaluation_mode.dart';
import '../../enums/syllabus_topic_kind.dart';

part 'teaching_guide.freezed.dart';

/// Guía docente de una asignatura extraída con IA.
@freezed
abstract class TeachingGuide with _$TeachingGuide {
  const factory TeachingGuide({
    required String subjectId,
    @Default(SubjectGuideInfo()) SubjectGuideInfo info,
    @Default(<Professor>[]) List<Professor> professors,
    @Default(<SyllabusTopic>[]) List<SyllabusTopic> topics,
    @Default(<Assessment>[]) List<Assessment> assessments,
    @Default(<String>[]) List<String> bibliography,

    /// Modalidades que aparecen en la guía; con dos, el estudiante elige.
    @Default(<EvaluationMode>[]) List<EvaluationMode> availableModes,
    EvaluationMode? effectiveMode,
    required double syllabusProgress,
    GradeEstimate? estimate,
    DateTime? updatedAt,
  }) = _TeachingGuide;
}

/// Datos de identificación de la asignatura según su plan docente.
@freezed
abstract class SubjectGuideInfo with _$SubjectGuideInfo {
  const factory SubjectGuideInfo({
    String? name,
    String? code,
    double? ectsCredits,
    int? courseYear,
    int? semester,
    String? character,
    String? degree,
    String? center,
    String? university,
    String? academicYear,
    String? department,
    String? description,
  }) = _SubjectGuideInfo;
}

/// Profesor de la asignatura.
@freezed
abstract class Professor with _$Professor {
  const factory Professor({
    required String name,
    String? email,
    String? office,
  }) = _Professor;
}

/// Tema del temario, marcable como completado.
@freezed
abstract class SyllabusTopic with _$SyllabusTopic {
  const factory SyllabusTopic({
    required int index,
    required String title,
    required SyllabusTopicKind kind,
    required bool completed,
    @Default(<String>[]) List<String> subtopics,

    /// Horas de trabajo del alumno según la tabla de actividades formativas.
    double? hours,
  }) = _SyllabusTopic;
}

/// Criterio de evaluación con su peso y la nota que haya puesto el usuario.
@freezed
abstract class Assessment with _$Assessment {
  const factory Assessment({
    required int index,
    required String name,
    required double percentage,
    double? grade,
    EvaluationMode? mode,
    @Default(AssessmentKind.other) AssessmentKind kind,
    int? durationMinutes,

    /// Temas que entran (1 = primer tema del temario).
    @Default(<int>[]) List<int> topicNumbers,
    bool? recoverable,
    DateTime? dueDate,

    /// Cuenta para la nota con la modalidad activa.
    @Default(true) bool active,
  }) = _Assessment;
}

/// Estimación de la nota final calculada por el servidor.
@freezed
abstract class GradeEstimate with _$GradeEstimate {
  const factory GradeEstimate({
    required double estimatedGrade,
    required double coveredPercentage,
    double? requiredGradeToPass,
    String? nextPendingAssessment,
  }) = _GradeEstimate;
}
