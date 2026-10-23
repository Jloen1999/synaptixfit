package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No se puede cerrar el onboarding sin haber guardado el perfil de bienestar. */
public class OnboardingRequiresWellnessProfileException extends BusinessRuleException {

    public OnboardingRequiresWellnessProfileException() {
        super("PROFILE_ONBOARDING_WELLNESS_REQUIRED", "The wellness profile is required to complete the onboarding");
    }
}
