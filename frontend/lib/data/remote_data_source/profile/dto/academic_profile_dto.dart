import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/profile/study_modality.dart';
import '../../../../domain/models/profile/academic_profile.dart';

part 'academic_profile_dto.freezed.dart';
part 'academic_profile_dto.g.dart';

@freezed
abstract class AcademicProfileDto with _$AcademicProfileDto {
  const factory AcademicProfileDto({
    String? university,
    String? degree,
    int? semester,
    String? modality,
    int? semesterCredits,
    int? weeklyStudyHoursGoal,
    double? targetGpa,
    String? classesStartDate,
    String? classesEndDate,
  }) = _AcademicProfileDto;

  const AcademicProfileDto._();

  factory AcademicProfileDto.fromJson(Map<String, dynamic> json) =>
      _$AcademicProfileDtoFromJson(json);

  AcademicProfile toDomain() => AcademicProfile(
    university: university,
    degree: degree,
    semester: semester,
    modality: StudyModality.fromApi(modality),
    semesterCredits: semesterCredits,
    weeklyStudyHoursGoal: weeklyStudyHoursGoal,
    targetGpa: targetGpa,
    classesStartDate: parseLocalDate(classesStartDate),
    classesEndDate: parseLocalDate(classesEndDate),
  );
}

/// Fecha sin hora de la API (`yyyy-MM-dd`) → `DateTime` local a medianoche.
DateTime? parseLocalDate(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// `DateTime` → fecha `yyyy-MM-dd` para la API.
String formatLocalDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Cuerpo de PUT `/profile/academic`. Los campos vacíos no se envían.
Map<String, dynamic> academicDraftToJson(AcademicProfileDraft draft) {
  final start = draft.classesStartDate;
  final end = draft.classesEndDate;
  return {
    'university': ?draft.university,
    'degree': ?draft.degree,
    'degreeId': ?draft.degreeId,
    'semester': ?draft.semester,
    'modality': ?draft.modality?.apiValue,
    'semesterCredits': ?draft.semesterCredits,
    'weeklyStudyHoursGoal': ?draft.weeklyStudyHoursGoal,
    'targetGpa': ?draft.targetGpa,
    if (start != null) 'classesStartDate': formatLocalDate(start),
    if (end != null) 'classesEndDate': formatLocalDate(end),
  };
}
