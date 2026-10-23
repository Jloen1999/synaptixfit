package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import java.util.UUID;

/** Devuelve el perfil académico del usuario. */
public interface GetAcademicProfileUseCase {

    AcademicProfile getAcademicProfile(UUID userId);
}
