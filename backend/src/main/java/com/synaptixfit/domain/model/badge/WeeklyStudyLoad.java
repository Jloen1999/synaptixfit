package com.synaptixfit.domain.model.badge;

import java.time.LocalDate;

/** Horas de estudio planificadas y reales de una semana. */
public record WeeklyStudyLoad(LocalDate weekStart, int plannedHours, int actualHours) {

    /** Adherencia suficiente: al menos el 80 % de lo planificado. */
    public boolean adherent() {
        return plannedHours > 0 && actualHours >= plannedHours * 0.8;
    }
}
