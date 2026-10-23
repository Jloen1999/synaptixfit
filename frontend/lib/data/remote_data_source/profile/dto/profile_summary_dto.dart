import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/profile/onboarding_step.dart';
import '../../../../domain/models/profile/onboarding_status.dart';
import '../../../../domain/models/profile/profile_summary.dart';
import 'academic_profile_dto.dart';
import 'catalog_dto.dart';
import 'wellness_profile_dto.dart';

part 'profile_summary_dto.freezed.dart';
part 'profile_summary_dto.g.dart';

@freezed
abstract class OnboardingStatusDto with _$OnboardingStatusDto {
  const factory OnboardingStatusDto({
    @Default(false) bool completed,
    @Default(<String>[]) List<String> pendingSteps,
  }) = _OnboardingStatusDto;

  const OnboardingStatusDto._();

  factory OnboardingStatusDto.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStatusDtoFromJson(json);

  OnboardingStatus toDomain() => OnboardingStatus(
    completed: completed,
    pendingSteps: pendingSteps
        .map(OnboardingStep.fromApi)
        .whereType<OnboardingStep>()
        .toList(),
  );
}

@freezed
abstract class ProfileSummaryDto with _$ProfileSummaryDto {
  const factory ProfileSummaryDto({
    WellnessProfileDto? wellness,
    AcademicProfileDto? academic,
    @Default(<UserDegreeDto>[]) List<UserDegreeDto> degrees,
    OnboardingStatusDto? onboarding,
  }) = _ProfileSummaryDto;

  const ProfileSummaryDto._();

  factory ProfileSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryDtoFromJson(json);

  ProfileSummary toDomain() => ProfileSummary(
    wellness: wellness?.toDomain(),
    academic: academic?.toDomain(),
    degrees: degrees.map((d) => d.toDomain()).toList(),
    onboarding:
        onboarding?.toDomain() ?? const OnboardingStatus(completed: false),
  );
}
