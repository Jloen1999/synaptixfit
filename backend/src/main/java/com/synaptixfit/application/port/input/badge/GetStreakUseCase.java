package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.StreakStatus;
import java.util.UUID;

/** Racha diaria del usuario (sesiones o check-ins); actualiza {@code usuarios.racha_actual}. */
public interface GetStreakUseCase {

    StreakStatus getStreak(UUID userId, String zone);
}
