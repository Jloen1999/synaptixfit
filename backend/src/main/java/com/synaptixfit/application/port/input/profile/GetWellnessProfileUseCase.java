package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.WellnessProfile;
import java.util.UUID;

/** Devuelve el perfil de bienestar del usuario. */
public interface GetWellnessProfileUseCase {

    WellnessProfile getWellnessProfile(UUID userId);
}
