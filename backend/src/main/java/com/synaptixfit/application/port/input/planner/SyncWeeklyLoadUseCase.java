package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Recalcula la carga académica de la semana (horas planificadas y reales de estudio, exámenes y
 * entregas) a partir de bloques y entregas y concede la experiencia semanal de estudio si procede.
 */
public interface SyncWeeklyLoadUseCase {

    /** @param xpAwarded experiencia dada en esta operación */
    record Result(WeeklyAcademicLoad load, int xpAwarded) {
    }

    Result syncWeek(UUID userId, LocalDate weekStart);
}
