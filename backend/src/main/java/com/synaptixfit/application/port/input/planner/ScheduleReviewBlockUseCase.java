package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Prepara el bloque de repaso (no fijo, 30 min) de la siguiente fecha SM-2 de un material: si ya hay
 * uno pendiente para ese material lo mueve a la nueva fecha; si no, lo crea. Si la hora choca con
 * otro bloque se desplaza al primer hueco libre del mismo día. Idempotente (lo invoca el oyente de
 * {@code ReviewScheduled}).
 */
public interface ScheduleReviewBlockUseCase {

    record Command(UUID userId, UUID studyMaterialId, UUID subjectId, String title, Instant dueAt) {
    }

    Optional<CalendarBlock> scheduleReview(Command command);
}
