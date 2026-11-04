package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.SessionAdaptation;
import java.util.UUID;

/**
 * Cómo se adaptaría hoy el entreno y por qué, sin empezar ninguna sesión: lo enseña la tarjeta del registro rápido
 * («Hoy hacemos menos series porque dormiste mal»).
 */
public interface GetTodayAdaptationUseCase {

    /** @param todayCheckIn registro diario de hoy, o nulo si aún no hay (sus respuestas rellenan «Cambiar») */
    record Result(SessionAdaptation adaptation, DailyCheckIn todayCheckIn) {

        public boolean checkInDone() {
            return todayCheckIn != null;
        }
    }

    Result today(UUID userId, String timeZone);
}
