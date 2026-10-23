package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Bloques del usuario que se solapan con un rango (p. ej. la semana del lienzo), opcionalmente de una asignatura. */
public interface GetCalendarBlocksUseCase {

    List<CalendarBlock> getBlocks(UUID userId, Instant from, Instant to, UUID subjectId);
}
