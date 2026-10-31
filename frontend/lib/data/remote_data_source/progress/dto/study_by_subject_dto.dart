import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/progress/study_by_subject.dart';

part 'study_by_subject_dto.freezed.dart';
part 'study_by_subject_dto.g.dart';

/// `GET /api/v1/analytics/study-subjects`.
@freezed
abstract class StudyBySubjectDto with _$StudyBySubjectDto {
  const factory StudyBySubjectDto({
    required String firstWeek,
    @Default(4) int weeks,
    @Default(<SubjectStudyDto>[]) List<SubjectStudyDto> subjects,
  }) = _StudyBySubjectDto;

  const StudyBySubjectDto._();

  factory StudyBySubjectDto.fromJson(Map<String, dynamic> json) =>
      _$StudyBySubjectDtoFromJson(json);

  StudyBySubject toDomain() => StudyBySubject(
    firstWeek: DateTime.parse(firstWeek),
    weeks: weeks,
    subjects: [for (final s in subjects) s.toDomain()],
  );
}

@freezed
abstract class SubjectStudyDto with _$SubjectStudyDto {
  const factory SubjectStudyDto({
    String? subjectId,
    String? name,
    @Default(0) int totalMinutes,
    @Default(<int>[]) List<int> minutesByWeek,
    @Default(0) int reviews,
    double? recallRate,
    @Default(false) bool weak,
  }) = _SubjectStudyDto;

  const SubjectStudyDto._();

  factory SubjectStudyDto.fromJson(Map<String, dynamic> json) =>
      _$SubjectStudyDtoFromJson(json);

  SubjectStudy toDomain() => SubjectStudy(
    subjectId: subjectId,
    name: name,
    totalMinutes: totalMinutes,
    minutesByWeek: minutesByWeek,
    reviews: reviews,
    recallRate: recallRate,
    weak: weak,
  );
}
