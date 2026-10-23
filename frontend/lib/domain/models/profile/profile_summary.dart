import 'package:freezed_annotation/freezed_annotation.dart';

import 'academic_profile.dart';
import 'catalog.dart';
import 'onboarding_status.dart';
import 'wellness_profile.dart';

part 'profile_summary.freezed.dart';

/// Resumen del perfil: físico, académico, carreras y estado del onboarding.
@freezed
abstract class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({
    WellnessProfile? wellness,
    AcademicProfile? academic,
    @Default(<UserDegree>[]) List<UserDegree> degrees,
    required OnboardingStatus onboarding,
  }) = _ProfileSummary;
}
