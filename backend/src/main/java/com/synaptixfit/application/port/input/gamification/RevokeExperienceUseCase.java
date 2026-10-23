package com.synaptixfit.application.port.input.gamification;

import com.synaptixfit.domain.model.user.ExperienceChange;
import java.util.UUID;

/** Resta experiencia (por ejemplo al desmarcar una tarea completada). */
public interface RevokeExperienceUseCase {

    ExperienceChange revoke(UUID userId, int amount);
}
