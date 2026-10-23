package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.OnboardingStatus;
import java.util.UUID;

/** Indica qué pasos del onboarding faltan. */
public interface GetOnboardingStatusUseCase {

    OnboardingStatus getOnboardingStatus(UUID userId);
}
