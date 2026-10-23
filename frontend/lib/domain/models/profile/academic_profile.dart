import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/profile/study_modality.dart';

part 'academic_profile.freezed.dart';

/// Perfil académico del usuario.
@freezed
abstract class AcademicProfile with _$AcademicProfile {
  const factory AcademicProfile({
    String? university,
    String? degree,
    int? semester,
    StudyModality? modality,
    int? semesterCredits,
    int? weeklyStudyHoursGoal,
    double? targetGpa,
    DateTime? classesStartDate,
    DateTime? classesEndDate,
  }) = _AcademicProfile;
}

/// Datos del formulario del perfil académico. Si [degreeId] viene informado,
/// el backend toma universidad y carrera del catálogo y vincula la carrera.
@freezed
abstract class AcademicProfileDraft with _$AcademicProfileDraft {
  const factory AcademicProfileDraft({
    String? university,
    String? degree,
    String? degreeId,
    int? semester,
    StudyModality? modality,
    int? semesterCredits,
    int? weeklyStudyHoursGoal,
    double? targetGpa,
    DateTime? classesStartDate,
    DateTime? classesEndDate,
  }) = _AcademicProfileDraft;
}
