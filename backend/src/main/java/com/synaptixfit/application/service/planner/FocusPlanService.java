package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.planner.GetFocusPlanUseCase;
import com.synaptixfit.domain.model.planner.FocusPlan;
import java.util.UUID;

/**
 * Implementa GetFocusPlanUseCase: lee la regulación cruzada de hoy (GetCrossRegulationUseCase) y
 * deriva las duraciones del Pomodoro con {@link FocusPlan}.
 */
public class FocusPlanService implements GetFocusPlanUseCase {

    private final GetCrossRegulationUseCase crossRegulation;

    public FocusPlanService(GetCrossRegulationUseCase crossRegulation) {
        this.crossRegulation = crossRegulation;
    }

    @Override
    public FocusPlan getFocusPlan(UUID userId, String timeZone) {
        return FocusPlan.of(crossRegulation.getCrossRegulation(userId, timeZone));
    }
}
