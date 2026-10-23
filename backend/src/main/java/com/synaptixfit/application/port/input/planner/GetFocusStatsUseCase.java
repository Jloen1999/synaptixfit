package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.FocusStats;
import java.time.LocalDate;
import java.util.UUID;

/** Estadísticas Pomodoro del día indicado (nulo: hoy) y de su semana. */
public interface GetFocusStatsUseCase {

    FocusStats getStats(UUID userId, LocalDate date);
}
