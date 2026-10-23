import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/assessment_kind.dart';
import '../../enums/evaluation_mode.dart';
import '../../enums/syllabus_topic_kind.dart';
import '../../enums/teaching_guide_import_status.dart';
import 'teaching_guide.dart';

part 'teaching_guide_import.freezed.dart';

/// Importación de un plan docente en PDF: la IA lo analiza en el servidor y el
/// estudiante revisa el [draft] antes de aplicarlo a una asignatura.
@freezed
abstract class TeachingGuideImport with _$TeachingGuideImport {
  const factory TeachingGuideImport({
    required String id,
    required TeachingGuideImportStatus status,
    String? errorCode,
    required String fileName,
    String? targetSubjectId,

    /// Asignatura del usuario que coincide con la del plan (por código o nombre).
    String? suggestedSubjectId,
    String? suggestedSubjectName,
    String? appliedSubjectId,
    GuideDraft? draft,
  }) = _TeachingGuideImport;
}

/// Guía extraída y editable antes de aplicarla.
@freezed
abstract class GuideDraft with _$GuideDraft {
  const GuideDraft._();

  const factory GuideDraft({
    @Default(SubjectGuideInfo()) SubjectGuideInfo info,
    @Default(<Professor>[]) List<Professor> professors,
    @Default(<TopicDraft>[]) List<TopicDraft> topics,
    @Default(<AssessmentDraft>[]) List<AssessmentDraft> assessments,
    @Default(<String>[]) List<String> bibliography,
    EvaluationMode? selectedMode,
  }) = _GuideDraft;

  /// Modalidades presentes, en el orden continua → global.
  List<EvaluationMode> get modes => EvaluationMode.values
      .where((m) => assessments.any((a) => a.mode == m))
      .toList();

  /// Igual que el servidor (TeachingGuide.effectiveMode): se repite aquí solo
  /// para que la revisión muestre al instante qué criterios cuentan mientras
  /// se edita; al aplicar, la regla la vuelve a calcular el servidor.
  EvaluationMode? get effectiveMode {
    final available = modes;
    if (available.isEmpty) return null;
    if (selectedMode != null && available.contains(selectedMode)) {
      return selectedMode;
    }
    return available.contains(EvaluationMode.continuous)
        ? EvaluationMode.continuous
        : available.first;
  }

  /// Criterios que cuentan con la modalidad activa (con su posición original).
  List<(int, AssessmentDraft)> get activeAssessments {
    final mode = effectiveMode;
    return [
      for (var i = 0; i < assessments.length; i++)
        if (mode == null ||
            assessments[i].mode == null ||
            assessments[i].mode == mode)
          (i, assessments[i]),
    ];
  }

  /// Suma de pesos de la modalidad activa (debería ser 100).
  double get activeTotal =>
      activeAssessments.fold(0, (sum, e) => sum + e.$2.percentage);
}

/// Tema del borrador.
@freezed
abstract class TopicDraft with _$TopicDraft {
  const factory TopicDraft({
    required String title,
    @Default(SyllabusTopicKind.theory) SyllabusTopicKind kind,
    @Default(<String>[]) List<String> subtopics,
    double? hours,
  }) = _TopicDraft;
}

/// Prueba del borrador; con [dueDate] se puede crear en el planificador.
@freezed
abstract class AssessmentDraft with _$AssessmentDraft {
  const factory AssessmentDraft({
    required String name,
    required double percentage,
    EvaluationMode? mode,
    @Default(AssessmentKind.other) AssessmentKind kind,
    int? durationMinutes,
    @Default(<int>[]) List<int> topicNumbers,
    bool? recoverable,
    DateTime? dueDate,
  }) = _AssessmentDraft;
}

/// Resultado de aplicar un plan docente.
@freezed
abstract class TeachingGuideImportResult with _$TeachingGuideImportResult {
  const factory TeachingGuideImportResult({
    required String subjectId,
    required bool subjectCreated,
    required int deadlinesRequested,
  }) = _TeachingGuideImportResult;
}
