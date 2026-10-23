package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.DailyCheckIn;
import java.util.UUID;

/** Guarda el check-in de hoy (crea o actualiza). Solo el primero del día da experiencia. */
public interface SubmitDailyCheckInUseCase {

    Result submit(UUID userId, DailyCheckIn.Values values);

    record Result(DailyCheckIn checkIn, boolean firstOfDay, int xpAwarded) {
    }
}
