import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/user_role.dart';
import '../../enums/visibility.dart';

part 'admin_user.freezed.dart';

/// Fila del listado de usuarios.
@freezed
abstract class AdminUserSummary with _$AdminUserSummary {
  const factory AdminUserSummary({
    required String id,
    required String email,
    required String fullName,
    String? avatarUrl,
    required UserRole role,
    required int level,
    required int levelXp,
    required int levelThreshold,
    required int totalXp,
    required int streak,
    required bool shadowbanned,
    required bool deleted,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) = _AdminUserSummary;
}

/// Cuenta completa de un usuario vista por un administrador.
@freezed
abstract class AdminUserAccount with _$AdminUserAccount {
  const factory AdminUserAccount({
    required String id,
    required String email,
    required String fullName,
    String? avatarUrl,
    required UserRole role,
    required int level,
    required int levelXp,
    required int levelThreshold,
    required int totalXp,
    required int streak,
    required Visibility privacy,
    required bool shadowbanned,
    required bool hasPassword,
    required bool googleLinked,
    required bool deleted,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) = _AdminUserAccount;
}

/// Perfil físico y de bienestar del usuario.
@freezed
abstract class AdminWellbeingProfile with _$AdminWellbeingProfile {
  const factory AdminWellbeingProfile({
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
  }) = _AdminWellbeingProfile;
}

/// Perfil académico del usuario.
@freezed
abstract class AdminAcademicProfile with _$AdminAcademicProfile {
  const factory AdminAcademicProfile({
    String? university,
    String? degree,
    int? currentSemester,
    String? modality,
    int? semesterCredits,
    int? weeklyStudyHoursGoal,
    double? targetGrade,
    DateTime? classesStart,
    DateTime? classesEnd,
  }) = _AdminAcademicProfile;
}

/// Detalle de un usuario: cuenta y perfiles (pueden no existir).
@freezed
abstract class AdminUserDetail with _$AdminUserDetail {
  const factory AdminUserDetail({
    required AdminUserAccount account,
    AdminWellbeingProfile? wellbeingProfile,
    AdminAcademicProfile? academicProfile,
  }) = _AdminUserDetail;
}
