import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/assessment_kind.dart';
import '../../../../domain/enums/evaluation_mode.dart';
import '../../../../domain/enums/subject_priority.dart';
import '../../../../domain/enums/subject_timeline_type.dart';
import '../../../../domain/enums/syllabus_topic_kind.dart';
import '../../../../domain/models/academic/subject.dart';
import '../../../../domain/models/academic/subject_timeline_item.dart';
import '../../../../domain/models/academic/teaching_guide.dart';

part 'subject_dtos.freezed.dart';
part 'subject_dtos.g.dart';

@freezed
abstract class SubjectDto with _$SubjectDto {
  const factory SubjectDto({
    required String id,
    required String name,
    String? code,
    String? description,
    @Default(0) int credits,
    @Default(0) int perceivedDifficulty,
    String? priority,
    DateTime? nextAssessmentAt,
    String? teacher,
    @Default(false) bool archived,
    String? catalogSubjectId,
    DateTime? createdAt,
    @Default(0) int noteCount,
    @Default(0) int fileCount,
  }) = _SubjectDto;

  const SubjectDto._();

  factory SubjectDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectDtoFromJson(json);

  Subject toDomain() => Subject(
    id: id,
    name: name,
    code: code,
    description: description,
    credits: credits,
    perceivedDifficulty: perceivedDifficulty,
    priority: SubjectPriority.fromApi(priority),
    nextAssessmentAt: nextAssessmentAt?.toLocal(),
    teacher: teacher,
    archived: archived,
    catalogSubjectId: catalogSubjectId,
    createdAt: createdAt?.toLocal(),
    noteCount: noteCount,
    fileCount: fileCount,
  );
}

@freezed
abstract class SubjectSemesterDto with _$SubjectSemesterDto {
  const factory SubjectSemesterDto({
    required String subjectId,
    required int course,
    required int semester,
  }) = _SubjectSemesterDto;

  const SubjectSemesterDto._();

  factory SubjectSemesterDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectSemesterDtoFromJson(json);

  SubjectSemester toDomain() =>
      SubjectSemester(subjectId: subjectId, course: course, semester: semester);
}

@freezed
abstract class RetentionDto with _$RetentionDto {
  const factory RetentionDto({
    @Default(0) int mastered,
    @Default(0) int inProgress,
    @Default(0) int needsReview,
    @Default(0) int notEvaluated,
    @Default(0) int abandoned,
    @Default(0) int total,
  }) = _RetentionDto;

  const RetentionDto._();

  factory RetentionDto.fromJson(Map<String, dynamic> json) =>
      _$RetentionDtoFromJson(json);

  Retention toDomain() => Retention(
    mastered: mastered,
    inProgress: inProgress,
    needsReview: needsReview,
    notEvaluated: notEvaluated,
    abandoned: abandoned,
    total: total,
  );
}

@freezed
abstract class TeachingGuideDto with _$TeachingGuideDto {
  const factory TeachingGuideDto({
    required String subjectId,
    SubjectGuideInfoDto? subject,
    @Default(<ProfessorDto>[]) List<ProfessorDto> professors,
    @Default(<TopicDto>[]) List<TopicDto> topics,
    @Default(<AssessmentDto>[]) List<AssessmentDto> assessments,
    @Default(<String>[]) List<String> bibliography,
    @Default(<String>[]) List<String> availableModes,
    String? effectiveMode,
    @Default(0) double syllabusProgress,
    GradeEstimateDto? estimate,
    DateTime? updatedAt,
  }) = _TeachingGuideDto;

  const TeachingGuideDto._();

  factory TeachingGuideDto.fromJson(Map<String, dynamic> json) =>
      _$TeachingGuideDtoFromJson(json);

  TeachingGuide toDomain() => TeachingGuide(
    subjectId: subjectId,
    info: subject?.toDomain() ?? const SubjectGuideInfo(),
    professors: professors.map((p) => p.toDomain()).toList(),
    topics: topics.map((t) => t.toDomain()).toList(),
    assessments: assessments.map((a) => a.toDomain()).toList(),
    bibliography: bibliography,
    availableModes: availableModes
        .map(EvaluationMode.fromApi)
        .whereType<EvaluationMode>()
        .toList(),
    effectiveMode: EvaluationMode.fromApi(effectiveMode),
    syllabusProgress: syllabusProgress,
    estimate: estimate?.toDomain(),
    updatedAt: updatedAt?.toLocal(),
  );
}

/// Datos de la asignatura según su plan docente (también en el borrador).
@freezed
abstract class SubjectGuideInfoDto with _$SubjectGuideInfoDto {
  const factory SubjectGuideInfoDto({
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
  }) = _SubjectGuideInfoDto;

  const SubjectGuideInfoDto._();

  factory SubjectGuideInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectGuideInfoDtoFromJson(json);

  factory SubjectGuideInfoDto.fromDomain(SubjectGuideInfo i) =>
      SubjectGuideInfoDto(
        name: i.name,
        code: i.code,
        ectsCredits: i.ectsCredits,
        courseYear: i.courseYear,
        semester: i.semester,
        character: i.character,
        degree: i.degree,
        center: i.center,
        university: i.university,
        academicYear: i.academicYear,
        department: i.department,
        description: i.description,
      );

  SubjectGuideInfo toDomain() => SubjectGuideInfo(
    name: name,
    code: code,
    ectsCredits: ectsCredits,
    courseYear: courseYear,
    semester: semester,
    character: character,
    degree: degree,
    center: center,
    university: university,
    academicYear: academicYear,
    department: department,
    description: description,
  );
}

@freezed
abstract class ProfessorDto with _$ProfessorDto {
  const factory ProfessorDto({String? name, String? email, String? office}) =
      _ProfessorDto;

  const ProfessorDto._();

  factory ProfessorDto.fromJson(Map<String, dynamic> json) =>
      _$ProfessorDtoFromJson(json);

  Professor toDomain() =>
      Professor(name: name ?? '', email: email, office: office);
}

@freezed
abstract class TopicDto with _$TopicDto {
  const factory TopicDto({
    required int index,
    @Default('') String title,
    String? kind,
    @Default(false) bool completed,
    @Default(<String>[]) List<String> subtopics,
    double? hours,
  }) = _TopicDto;

  const TopicDto._();

  factory TopicDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDtoFromJson(json);

  SyllabusTopic toDomain() => SyllabusTopic(
    index: index,
    title: title,
    kind: SyllabusTopicKind.fromApi(kind),
    completed: completed,
    subtopics: subtopics,
    hours: hours,
  );
}

@freezed
abstract class AssessmentDto with _$AssessmentDto {
  const factory AssessmentDto({
    required int index,
    @Default('') String name,
    @Default(0) double percentage,
    double? grade,
    String? mode,
    String? kind,
    int? durationMinutes,
    @Default(<int>[]) List<int> topicNumbers,
    bool? recoverable,
    DateTime? dueDate,
    @Default(true) bool active,
  }) = _AssessmentDto;

  const AssessmentDto._();

  factory AssessmentDto.fromJson(Map<String, dynamic> json) =>
      _$AssessmentDtoFromJson(json);

  Assessment toDomain() => Assessment(
    index: index,
    name: name,
    percentage: percentage,
    grade: grade,
    mode: EvaluationMode.fromApi(mode),
    kind: AssessmentKind.fromApi(kind),
    durationMinutes: durationMinutes,
    topicNumbers: topicNumbers,
    recoverable: recoverable,
    dueDate: dueDate,
    active: active,
  );
}

@freezed
abstract class GradeEstimateDto with _$GradeEstimateDto {
  const factory GradeEstimateDto({
    @Default(0) double estimatedGrade,
    @Default(0) double coveredPercentage,
    double? requiredGradeToPass,
    String? nextPendingAssessment,
  }) = _GradeEstimateDto;

  const GradeEstimateDto._();

  factory GradeEstimateDto.fromJson(Map<String, dynamic> json) =>
      _$GradeEstimateDtoFromJson(json);

  GradeEstimate toDomain() => GradeEstimate(
    estimatedGrade: estimatedGrade,
    coveredPercentage: coveredPercentage,
    requiredGradeToPass: requiredGradeToPass,
    nextPendingAssessment: nextPendingAssessment,
  );
}

/// Elemento de `GET /api/v1/planner/timeline` (solo lo que usa la asignatura).
@freezed
abstract class SubjectTimelineItemDto with _$SubjectTimelineItemDto {
  const factory SubjectTimelineItemDto({
    required String id,
    String? kind,
    String? blockType,
    String? deadlineType,
    @Default('') String title,
    required DateTime start,
    DateTime? end,
    @Default(false) bool completed,
    String? location,
  }) = _SubjectTimelineItemDto;

  const SubjectTimelineItemDto._();

  factory SubjectTimelineItemDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectTimelineItemDtoFromJson(json);

  SubjectTimelineItem toDomain() => SubjectTimelineItem(
    id: id,
    type: SubjectTimelineType.fromApi(
      kind: kind,
      blockType: blockType,
      deadlineType: deadlineType,
    ),
    isDeadline: kind == 'DEADLINE',
    title: title,
    start: start.toLocal(),
    end: end?.toLocal(),
    completed: completed,
    location: location,
  );
}
