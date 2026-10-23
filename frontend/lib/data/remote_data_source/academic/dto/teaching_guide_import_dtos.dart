import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/assessment_kind.dart';
import '../../../../domain/enums/evaluation_mode.dart';
import '../../../../domain/enums/syllabus_topic_kind.dart';
import '../../../../domain/enums/teaching_guide_import_status.dart';
import '../../../../domain/models/academic/teaching_guide.dart';
import '../../../../domain/models/academic/teaching_guide_import.dart';
import 'subject_dtos.dart';

part 'teaching_guide_import_dtos.freezed.dart';
part 'teaching_guide_import_dtos.g.dart';

/// Respuesta de `/api/v1/teaching-guide-imports`.
@freezed
abstract class TeachingGuideImportDto with _$TeachingGuideImportDto {
  const factory TeachingGuideImportDto({
    required String id,
    String? status,
    String? errorCode,
    @Default('') String fileName,
    String? targetSubjectId,
    String? suggestedSubjectId,
    String? suggestedSubjectName,
    String? appliedSubjectId,
    GuideDraftDto? guide,
  }) = _TeachingGuideImportDto;

  const TeachingGuideImportDto._();

  factory TeachingGuideImportDto.fromJson(Map<String, dynamic> json) =>
      _$TeachingGuideImportDtoFromJson(json);

  TeachingGuideImport toDomain() => TeachingGuideImport(
    id: id,
    status: TeachingGuideImportStatus.fromApi(status),
    errorCode: errorCode,
    fileName: fileName,
    targetSubjectId: targetSubjectId,
    suggestedSubjectId: suggestedSubjectId,
    suggestedSubjectName: suggestedSubjectName,
    appliedSubjectId: appliedSubjectId,
    draft: guide?.toDomain(),
  );
}

/// Borrador de guía: llega en la respuesta y se devuelve editado al aplicar.
@freezed
abstract class GuideDraftDto with _$GuideDraftDto {
  const factory GuideDraftDto({
    SubjectGuideInfoDto? subject,
    @Default(<ProfessorDto>[]) List<ProfessorDto> professors,
    @Default(<TopicDraftDto>[]) List<TopicDraftDto> topics,
    @Default(<AssessmentDraftDto>[]) List<AssessmentDraftDto> assessments,
    @Default(<String>[]) List<String> bibliography,
    String? selectedMode,
  }) = _GuideDraftDto;

  const GuideDraftDto._();

  factory GuideDraftDto.fromJson(Map<String, dynamic> json) =>
      _$GuideDraftDtoFromJson(json);

  factory GuideDraftDto.fromDomain(GuideDraft d) => GuideDraftDto(
    subject: SubjectGuideInfoDto.fromDomain(d.info),
    professors: d.professors
        .map(
          (p) => ProfessorDto(name: p.name, email: p.email, office: p.office),
        )
        .toList(),
    topics: d.topics
        .map(
          (t) => TopicDraftDto(
            title: t.title,
            kind: t.kind.apiValue,
            subtopics: t.subtopics,
            hours: t.hours,
          ),
        )
        .toList(),
    assessments: d.assessments
        .map(
          (a) => AssessmentDraftDto(
            name: a.name,
            percentage: a.percentage,
            mode: a.mode?.apiValue,
            kind: a.kind.apiValue,
            durationMinutes: a.durationMinutes,
            topicNumbers: a.topicNumbers,
            recoverable: a.recoverable,
            dueDate: a.dueDate == null ? null : _isoDay(a.dueDate!),
          ),
        )
        .toList(),
    bibliography: d.bibliography,
    selectedMode: d.selectedMode?.apiValue,
  );

  GuideDraft toDomain() => GuideDraft(
    info: subject?.toDomain() ?? const SubjectGuideInfo(),
    professors: professors.map((p) => p.toDomain()).toList(),
    topics: topics
        .map(
          (t) => TopicDraft(
            title: t.title,
            kind: SyllabusTopicKind.fromApi(t.kind),
            subtopics: t.subtopics,
            hours: t.hours,
          ),
        )
        .toList(),
    assessments: assessments
        .map(
          (a) => AssessmentDraft(
            name: a.name,
            percentage: a.percentage,
            mode: EvaluationMode.fromApi(a.mode),
            kind: AssessmentKind.fromApi(a.kind),
            durationMinutes: a.durationMinutes,
            topicNumbers: a.topicNumbers,
            recoverable: a.recoverable,
            dueDate: a.dueDate == null ? null : DateTime.tryParse(a.dueDate!),
          ),
        )
        .toList(),
    bibliography: bibliography,
    selectedMode: EvaluationMode.fromApi(selectedMode),
  );

  /// El servidor espera días ISO (`LocalDate`), sin hora ni zona.
  static String _isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

@freezed
abstract class TopicDraftDto with _$TopicDraftDto {
  const factory TopicDraftDto({
    @Default('') String title,
    String? kind,
    @Default(<String>[]) List<String> subtopics,
    double? hours,
  }) = _TopicDraftDto;

  factory TopicDraftDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDraftDtoFromJson(json);
}

@freezed
abstract class AssessmentDraftDto with _$AssessmentDraftDto {
  const factory AssessmentDraftDto({
    @Default('') String name,
    @Default(0) double percentage,
    String? mode,
    String? kind,
    int? durationMinutes,
    @Default(<int>[]) List<int> topicNumbers,
    bool? recoverable,
    String? dueDate,
  }) = _AssessmentDraftDto;

  factory AssessmentDraftDto.fromJson(Map<String, dynamic> json) =>
      _$AssessmentDraftDtoFromJson(json);
}

/// Respuesta de `POST /api/v1/teaching-guide-imports/{id}/apply`.
@freezed
abstract class ApplyImportResultDto with _$ApplyImportResultDto {
  const factory ApplyImportResultDto({
    required String subjectId,
    @Default(false) bool subjectCreated,
    @Default(0) int deadlinesRequested,
  }) = _ApplyImportResultDto;

  const ApplyImportResultDto._();

  factory ApplyImportResultDto.fromJson(Map<String, dynamic> json) =>
      _$ApplyImportResultDtoFromJson(json);

  TeachingGuideImportResult toDomain() => TeachingGuideImportResult(
    subjectId: subjectId,
    subjectCreated: subjectCreated,
    deadlinesRequested: deadlinesRequested,
  );
}
