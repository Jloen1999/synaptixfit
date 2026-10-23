package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.TimelineItem;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Línea de tiempo unificada de un rango: bloques y entregas/exámenes ordenados por inicio. Un bloque
 * de examen/entrega vinculado a una entrega del rango no se repite (aparece la entrega).
 */
public interface GetTimelineUseCase {

    List<TimelineItem> getTimeline(UUID userId, Instant from, Instant to, UUID subjectId);
}
