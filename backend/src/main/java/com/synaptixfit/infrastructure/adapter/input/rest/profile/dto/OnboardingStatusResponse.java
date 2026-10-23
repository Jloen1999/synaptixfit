package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.OnboardingStatus;
import com.synaptixfit.domain.model.profile.OnboardingStep;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.util.List;

/**
 * Estado del onboarding. {@code nextStep} es nulo cuando no queda ningún paso pendiente;
 * {@code usageFocus} es nulo mientras no se haya elegido.
 */
public record OnboardingStatusResponse(boolean completed, OnboardingStep nextStep, List<OnboardingStep> pendingSteps,
                                       boolean accountCompleted, UsageFocus usageFocus, boolean wellnessProfileCompleted,
                                       boolean academicProfileCompleted, boolean subjectsCompleted) {

    public static OnboardingStatusResponse from(OnboardingStatus s) {
        return new OnboardingStatusResponse(s.completed(), s.nextStep(), s.pendingSteps(), s.accountCompleted(),
                s.focus(), s.wellnessProfileCompleted(), s.academicProfileCompleted(), s.subjectsCompleted());
    }
}
