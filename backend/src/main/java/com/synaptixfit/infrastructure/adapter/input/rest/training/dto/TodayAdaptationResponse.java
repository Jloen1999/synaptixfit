package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.GetTodayAdaptationUseCase;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.FatigueCause;
import com.synaptixfit.domain.model.training.SessionAdaptation;
import java.util.List;

/**
 * Cómo se adapta hoy el entreno sin empezar sesión: factor de series, motivos, lo que más pesa en la fatiga (si es
 * un motivo), si ya hay registro diario hoy y sus respuestas (sueño, energía y agujetas, 1-5; nulas sin registro),
 * para que «Cambiar» parta de ellas.
 */
public record TodayAdaptationResponse(double volumeFactor, List<SessionAdaptation.Reason> reasons,
                                      FatigueCause fatigueCause, boolean checkInDone, Integer sleepQuality,
                                      Integer energy, Integer soreness) {

    public static TodayAdaptationResponse from(GetTodayAdaptationUseCase.Result r) {
        DailyCheckIn c = r.todayCheckIn();
        return new TodayAdaptationResponse(r.adaptation().volumeFactor(), r.adaptation().reasons(),
                r.adaptation().fatigueCause(), r.checkInDone(), c == null ? null : c.sleepQuality(),
                c == null ? null : c.energy(), c == null ? null : c.soreness());
    }
}
