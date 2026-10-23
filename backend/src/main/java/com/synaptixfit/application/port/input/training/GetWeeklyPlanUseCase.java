package com.synaptixfit.application.port.input.training;

import java.time.LocalDate;
import java.util.UUID;

/** Plan de una semana con las sesiones completadas en ella. */
public interface GetWeeklyPlanUseCase {

    WeeklyPlanProgress get(UUID userId, LocalDate weekStart);
}
