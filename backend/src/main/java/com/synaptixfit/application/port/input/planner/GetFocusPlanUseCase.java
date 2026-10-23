package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.FocusPlan;
import java.util.UUID;

/** Duraciones recomendadas para el Pomodoro de hoy (bloque, pausas) según la regulación cruzada. */
public interface GetFocusPlanUseCase {

    /** @param timeZone zona IANA del cliente (null: zona por defecto) */
    FocusPlan getFocusPlan(UUID userId, String timeZone);
}
