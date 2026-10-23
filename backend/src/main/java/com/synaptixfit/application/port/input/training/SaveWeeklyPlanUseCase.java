package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import java.time.LocalDate;
import java.util.UUID;

/** Crea o actualiza el plan de la semana que contiene {@code weekStart}. */
public interface SaveWeeklyPlanUseCase {

    WeeklyPlanProgress save(UUID userId, LocalDate weekStart, WeeklyTrainingPlan.Values values);
}
