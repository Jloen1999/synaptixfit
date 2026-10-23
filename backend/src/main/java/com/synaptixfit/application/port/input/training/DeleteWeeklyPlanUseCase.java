package com.synaptixfit.application.port.input.training;

import java.time.LocalDate;
import java.util.UUID;

/** Borra el plan de una semana. */
public interface DeleteWeeklyPlanUseCase {

    void delete(UUID userId, LocalDate weekStart);
}
