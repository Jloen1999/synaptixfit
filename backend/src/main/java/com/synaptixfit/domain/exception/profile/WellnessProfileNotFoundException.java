package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El usuario todavía no tiene perfil de bienestar. */
public class WellnessProfileNotFoundException extends ResourceNotFoundException {

    public WellnessProfileNotFoundException(UUID userId) {
        super("PROFILE_WELLNESS_NOT_FOUND", "Wellness profile of user", userId);
    }
}
