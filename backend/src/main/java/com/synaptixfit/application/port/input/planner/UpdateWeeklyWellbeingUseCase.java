package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import java.time.LocalDate;
import java.util.UUID;

/** Registra el estrés (1-10), el sueño medio (0-14 h) y notas de una semana. Los nulos no cambian. */
public interface UpdateWeeklyWellbeingUseCase {

    record Command(UUID userId, LocalDate weekStart, Integer stressLevel, Double sleepHours, String notes) {
    }

    WeeklyAcademicLoad updateWellbeing(Command command);
}
