package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.WeekBalance;
import java.time.LocalDate;
import java.util.UUID;

/** Balance estudio/deporte (planificado y real) de la semana que contiene {@code weekStart}. */
public interface GetWeekBalanceUseCase {

    WeekBalance getBalance(UUID userId, LocalDate weekStart);
}
