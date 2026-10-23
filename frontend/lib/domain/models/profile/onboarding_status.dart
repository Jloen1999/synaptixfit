import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/profile/onboarding_step.dart';

part 'onboarding_status.freezed.dart';

/// Qué pasos del onboarding quedan pendientes.
@freezed
abstract class OnboardingStatus with _$OnboardingStatus {
  const factory OnboardingStatus({
    required bool completed,
    @Default(<OnboardingStep>[]) List<OnboardingStep> pendingSteps,
  }) = _OnboardingStatus;
}
