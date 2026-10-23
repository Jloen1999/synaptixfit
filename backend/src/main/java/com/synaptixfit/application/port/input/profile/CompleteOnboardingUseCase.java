package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.OnboardingStatus;
import java.util.UUID;

/** Marca el onboarding como terminado (exige perfil de bienestar). Idempotente. */
public interface CompleteOnboardingUseCase {

    OnboardingStatus completeOnboarding(UUID userId);
}
