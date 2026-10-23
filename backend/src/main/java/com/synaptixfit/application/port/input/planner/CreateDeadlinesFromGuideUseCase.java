package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.DeadlineType;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Crea las entregas y exámenes de un plan docente aplicado. Idempotente: salta las que ya existen
 * en la asignatura con el mismo título el mismo día.
 */
public interface CreateDeadlinesFromGuideUseCase {

    record Item(String title, DeadlineType type, Instant dueAt, String description) {
    }

    record Command(UUID userId, UUID subjectId, List<Item> items) {
    }

    /** Devuelve cuántas se han creado. */
    int createFromGuide(Command command);
}
