package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.Priority;
import java.time.Instant;
import java.util.UUID;

/** Edita una entrega. Los campos nulos no cambian; {@code clearSubject} la desvincula de su asignatura. */
public interface UpdateDeadlineUseCase {

    record Command(UUID userId, UUID deadlineId, String title, DeadlineType type, Instant dueAt,
                   Priority difficulty, String description, UUID subjectId, boolean clearSubject) {
    }

    Deadline updateDeadline(Command command);
}
