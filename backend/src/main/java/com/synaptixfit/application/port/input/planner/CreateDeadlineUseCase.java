package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.Priority;
import java.time.Instant;
import java.util.UUID;

/** Crea una entrega, examen, presentación u otra evaluación. */
public interface CreateDeadlineUseCase {

    record Command(UUID userId, String title, DeadlineType type, Instant dueAt, Priority difficulty,
                   String description, UUID subjectId) {
    }

    Deadline createDeadline(Command command);
}
