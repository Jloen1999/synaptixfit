package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.SessionAdaptation;
import java.util.UUID;

/**
 * Cómo se adaptaría hoy el entreno y por qué, sin empezar ninguna sesión: lo enseña la tarjeta del registro rápido
 * («Hoy hacemos menos series porque dormiste mal»).
 */
public interface GetTodayAdaptationUseCase {

    /** @param checkInDone ya hay registro diario hoy */
    record Result(SessionAdaptation adaptation, boolean checkInDone) {
    }

    Result today(UUID userId, String timeZone);
}
