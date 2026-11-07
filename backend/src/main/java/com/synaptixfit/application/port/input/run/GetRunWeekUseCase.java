package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.RunWeek;
import java.time.LocalDate;
import java.util.UUID;

/** Tarjeta «Esta semana» de Correr para la semana (lunes a domingo) que contiene {@code date}. */
public interface GetRunWeekUseCase {

    RunWeek getWeek(UUID userId, LocalDate date);
}
