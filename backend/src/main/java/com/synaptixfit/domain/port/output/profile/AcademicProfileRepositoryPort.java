package com.synaptixfit.domain.port.output.profile;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import java.util.Optional;
import java.util.UUID;

/** Persistencia del perfil académico (uno por usuario). */
public interface AcademicProfileRepositoryPort {

    Optional<AcademicProfile> findByUserId(UUID userId);

    AcademicProfile save(AcademicProfile profile);
}
