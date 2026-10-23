package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.PlannerProfile;
import java.util.Optional;
import java.util.UUID;

/** Lectura de los perfiles de bienestar y académico (módulo de perfil). */
public interface PlannerProfilePort {

    Optional<PlannerProfile.Metabolic> findMetabolic(UUID userId);

    Optional<PlannerProfile.Academic> findAcademic(UUID userId);
}
