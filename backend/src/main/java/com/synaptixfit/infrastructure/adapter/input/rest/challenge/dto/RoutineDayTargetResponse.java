package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import java.util.UUID;

/**
 * Día de la rutina en curso al que se puede vincular una tarea de reto. {@code dayNumber}: día de la semana
 * (1 = lunes); {@code dayName} nulo si no tiene nombre.
 */
public record RoutineDayTargetResponse(UUID dayId, String routineName, int weekNumber, int dayNumber,
                                       String dayName) {

    public static RoutineDayTargetResponse from(RoutineDayTarget t) {
        return new RoutineDayTargetResponse(t.dayId(), t.routineName(), t.weekNumber(), t.dayNumber(), t.dayName());
    }
}
