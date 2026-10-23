package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Cargas académicas guardadas de las semanas entre dos fechas (las usa la analítica). */
public interface GetWeeklyLoadsUseCase {

    List<WeeklyAcademicLoad> getWeeklyLoads(UUID userId, LocalDate from, LocalDate to);
}
