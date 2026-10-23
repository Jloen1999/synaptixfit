package com.synaptixfit.domain.port.output.profile;

import com.synaptixfit.domain.model.profile.WellnessProfile;
import java.util.Optional;
import java.util.UUID;

/** Persistencia del perfil de bienestar (uno por usuario). */
public interface WellnessProfileRepositoryPort {

    Optional<WellnessProfile> findByUserId(UUID userId);

    WellnessProfile save(WellnessProfile profile);
}
