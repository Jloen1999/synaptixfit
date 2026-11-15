package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.StudyRoomTimes;
import jakarta.validation.constraints.NotNull;

/** Minutos nuevos de una sala que aún no ha empezado (ADR 0053); el dominio comprueba los límites. */
public record StudyRoomTimesRequest(@NotNull Integer focusMinutes, @NotNull Integer breakMinutes) {

    public StudyRoomTimes times() {
        return new StudyRoomTimes(focusMinutes, breakMinutes);
    }
}
