import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/profile/activity_level.dart';
import '../../../../domain/enums/profile/fitness_goal.dart';
import '../../../../domain/enums/profile/sex.dart';
import '../../../../domain/models/profile/wellness_profile.dart';

part 'wellness_profile_dto.freezed.dart';
part 'wellness_profile_dto.g.dart';

@freezed
abstract class WellnessProfileDto with _$WellnessProfileDto {
  const factory WellnessProfileDto({
    int? age,
    String? sex,
    String? city,
    double? weightKg,
    double? heightCm,
    double? bmi,
    String? activityLevel,
    String? primaryGoal,
    String? primaryGoalLabel,
    List<String>? equipment,
    List<int>? availableDays,
    int? minutesPerSession,
    bool? onboardingCompleted,
  }) = _WellnessProfileDto;

  const WellnessProfileDto._();

  factory WellnessProfileDto.fromJson(Map<String, dynamic> json) =>
      _$WellnessProfileDtoFromJson(json);

  WellnessProfile toDomain() => WellnessProfile(
    age: age,
    sex: Sex.fromApi(sex),
    city: city,
    weightKg: weightKg,
    heightCm: heightCm,
    bmi: bmi,
    activityLevel: ActivityLevel.fromApi(activityLevel),
    primaryGoal: FitnessGoal.fromApi(primaryGoal),
    primaryGoalLabel: primaryGoalLabel,
    equipment: equipment ?? const [],
    availableDays: [...?availableDays]..sort(),
    minutesPerSession: minutesPerSession,
    onboardingCompleted: onboardingCompleted ?? false,
  );
}

/// Cuerpo de PUT/PATCH `/profile/wellness` a partir del borrador del formulario.
Map<String, dynamic> wellnessDraftToJson(WellnessProfileDraft draft) => {
  'age': draft.age,
  'sex': draft.sex.apiValue,
  'weightKg': draft.weightKg,
  'heightCm': draft.heightCm,
  'activityLevel': ?draft.activityLevel?.apiValue,
  'primaryGoal': draft.primaryGoal.apiValue,
  'equipment': draft.equipment,
  if (draft.availableDays != null)
    'availableDays': [...draft.availableDays!]..sort(),
  'minutesPerSession': ?draft.minutesPerSession,
};
