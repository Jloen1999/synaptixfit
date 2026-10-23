import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/admin/admin_erasure_mode.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/admin/admin_user.dart';
import '../../../../domain/models/admin/erasure_report.dart';
import 'admin_json.dart';

part 'admin_user_dto.freezed.dart';
part 'admin_user_dto.g.dart';

@freezed
abstract class AdminUserSummaryDto with _$AdminUserSummaryDto {
  const factory AdminUserSummaryDto({
    required String id,
    @Default('') String email,
    @Default('') String fullName,
    String? avatarUrl,
    String? role,
    @Default(1) int level,
    @Default(0) int levelXp,
    @Default(0) int levelThreshold,
    @Default(0) int totalXp,
    @Default(0) int streak,
    @Default(false) bool shadowbanned,
    @Default(false) bool deleted,
    String? createdAt,
    String? deletedAt,
  }) = _AdminUserSummaryDto;

  const AdminUserSummaryDto._();

  factory AdminUserSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$AdminUserSummaryDtoFromJson(json);

  AdminUserSummary toDomain() => AdminUserSummary(
    id: id,
    email: email,
    fullName: fullName,
    avatarUrl: avatarUrl,
    role: UserRole.fromApi(role),
    level: level,
    levelXp: levelXp,
    levelThreshold: levelThreshold,
    totalXp: totalXp,
    streak: streak,
    shadowbanned: shadowbanned,
    deleted: deleted,
    createdAt: AdminJson.instant(createdAt),
    deletedAt: AdminJson.instant(deletedAt),
  );
}

@freezed
abstract class AdminUserAccountDto with _$AdminUserAccountDto {
  const factory AdminUserAccountDto({
    required String id,
    @Default('') String email,
    @Default('') String fullName,
    String? avatarUrl,
    String? role,
    @Default(1) int level,
    @Default(0) int levelXp,
    @Default(0) int levelThreshold,
    @Default(0) int totalXp,
    @Default(0) int streak,
    String? privacy,
    @Default(false) bool shadowbanned,
    @Default(false) bool hasPassword,
    @Default(false) bool googleLinked,
    @Default(false) bool deleted,
    String? createdAt,
    String? deletedAt,
  }) = _AdminUserAccountDto;

  const AdminUserAccountDto._();

  factory AdminUserAccountDto.fromJson(Map<String, dynamic> json) =>
      _$AdminUserAccountDtoFromJson(json);

  AdminUserAccount toDomain() => AdminUserAccount(
    id: id,
    email: email,
    fullName: fullName,
    avatarUrl: avatarUrl,
    role: UserRole.fromApi(role),
    level: level,
    levelXp: levelXp,
    levelThreshold: levelThreshold,
    totalXp: totalXp,
    streak: streak,
    privacy: Visibility.fromApi(privacy),
    shadowbanned: shadowbanned,
    hasPassword: hasPassword,
    googleLinked: googleLinked,
    deleted: deleted,
    createdAt: AdminJson.instant(createdAt),
    deletedAt: AdminJson.instant(deletedAt),
  );
}

@freezed
abstract class AdminWellbeingProfileDto with _$AdminWellbeingProfileDto {
  const factory AdminWellbeingProfileDto({
    int? age,
    String? sex,
    double? weightKg,
    double? heightCm,
    double? bmi,
    String? activityLevel,
    String? mainGoal,
    int? availableDaysPerWeek,
    int? minutesPerSession,
    @Default(false) bool onboardingCompleted,
  }) = _AdminWellbeingProfileDto;

  const AdminWellbeingProfileDto._();

  factory AdminWellbeingProfileDto.fromJson(Map<String, dynamic> json) =>
      _$AdminWellbeingProfileDtoFromJson(json);

  AdminWellbeingProfile toDomain() => AdminWellbeingProfile(
    age: age,
    sex: sex,
    weightKg: weightKg,
    heightCm: heightCm,
    bmi: bmi,
    activityLevel: activityLevel,
    mainGoal: mainGoal,
    availableDaysPerWeek: availableDaysPerWeek,
    minutesPerSession: minutesPerSession,
    onboardingCompleted: onboardingCompleted,
  );
}

@freezed
abstract class AdminAcademicProfileDto with _$AdminAcademicProfileDto {
  const factory AdminAcademicProfileDto({
    String? university,
    String? degree,
    int? currentSemester,
    String? modality,
    int? semesterCredits,
    int? weeklyStudyHoursGoal,
    double? targetGrade,
    String? classesStart,
    String? classesEnd,
  }) = _AdminAcademicProfileDto;

  const AdminAcademicProfileDto._();

  factory AdminAcademicProfileDto.fromJson(Map<String, dynamic> json) =>
      _$AdminAcademicProfileDtoFromJson(json);

  AdminAcademicProfile toDomain() => AdminAcademicProfile(
    university: university,
    degree: degree,
    currentSemester: currentSemester,
    modality: modality,
    semesterCredits: semesterCredits,
    weeklyStudyHoursGoal: weeklyStudyHoursGoal,
    targetGrade: targetGrade,
    classesStart: AdminJson.date(classesStart),
    classesEnd: AdminJson.date(classesEnd),
  );
}

@freezed
abstract class AdminUserDetailDto with _$AdminUserDetailDto {
  const factory AdminUserDetailDto({
    required AdminUserAccountDto account,
    AdminWellbeingProfileDto? wellbeingProfile,
    AdminAcademicProfileDto? academicProfile,
  }) = _AdminUserDetailDto;

  const AdminUserDetailDto._();

  factory AdminUserDetailDto.fromJson(Map<String, dynamic> json) =>
      _$AdminUserDetailDtoFromJson(json);

  AdminUserDetail toDomain() => AdminUserDetail(
    account: account.toDomain(),
    wellbeingProfile: wellbeingProfile?.toDomain(),
    academicProfile: academicProfile?.toDomain(),
  );
}

@freezed
abstract class ErasureReportDto with _$ErasureReportDto {
  const factory ErasureReportDto({
    required String userId,
    String? mode,
    @Default(0) int deletedRecords,
    @Default(0) int storedFiles,
    @Default(0) int failedFileDeletions,
  }) = _ErasureReportDto;

  const ErasureReportDto._();

  factory ErasureReportDto.fromJson(Map<String, dynamic> json) =>
      _$ErasureReportDtoFromJson(json);

  ErasureReport toDomain() => ErasureReport(
    userId: userId,
    mode: AdminErasureMode.fromApi(mode),
    deletedRecords: deletedRecords,
    storedFiles: storedFiles,
    failedFileDeletions: failedFileDeletions,
  );
}
