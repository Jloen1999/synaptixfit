package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.ScheduleConflicts;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Pares de bloques solapados en la semana que contiene {@code weekStart}. */
public interface GetScheduleConflictsUseCase {

    List<ScheduleConflicts.Pair> getConflicts(UUID userId, LocalDate weekStart);
}
