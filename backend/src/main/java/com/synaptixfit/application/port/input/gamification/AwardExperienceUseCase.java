package com.synaptixfit.application.port.input.gamification;

import com.synaptixfit.domain.model.user.ExperienceChange;
import java.util.UUID;

/**
 * Suma experiencia a un usuario. Lo usan todas las funcionalidades que recompensan acciones.
 * Las cantidades no positivas no tienen efecto.
 */
public interface AwardExperienceUseCase {

    ExperienceChange award(UUID userId, int amount);
}
