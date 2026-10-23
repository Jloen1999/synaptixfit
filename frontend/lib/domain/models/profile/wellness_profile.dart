import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/profile/activity_level.dart';
import '../../enums/profile/fitness_goal.dart';
import '../../enums/profile/sex.dart';

part 'wellness_profile.freezed.dart';

/// Perfil físico (bienestar) del usuario. El IMC lo calcula el backend.
@freezed
abstract class WellnessProfile with _$WellnessProfile {
  const factory WellnessProfile({
    int? age,
    Sex? sex,
    String? city,
    double? weightKg,
    double? heightCm,
    double? bmi,
    ActivityLevel? activityLevel,
    FitnessGoal? primaryGoal,
    String? primaryGoalLabel,
    @Default(<String>[]) List<String> equipment,
    @Default(<int>[]) List<int> availableDays,
    int? minutesPerSession,
    @Default(false) bool onboardingCompleted,
  }) = _WellnessProfile;
}

/// Datos del formulario del perfil físico (alta completa o edición).
@freezed
abstract class WellnessProfileDraft with _$WellnessProfileDraft {
  const factory WellnessProfileDraft({
    required int age,
    required Sex sex,
    required double weightKg,
    required double heightCm,

    /// Nulos en el onboarding corto: el servidor pone sus valores por defecto
    /// (o conserva los que había).
    ActivityLevel? activityLevel,
    required FitnessGoal primaryGoal,
    required List<String> equipment,

    /// Días ISO (1 = lunes … 7 = domingo).
    List<int>? availableDays,
    int? minutesPerSession,
  }) = _WellnessProfileDraft;
}
