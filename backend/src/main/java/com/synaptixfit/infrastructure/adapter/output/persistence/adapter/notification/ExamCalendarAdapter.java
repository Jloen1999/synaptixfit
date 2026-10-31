package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.notification;

import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.port.output.notification.ExamCalendarPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Implementa {@link ExamCalendarPort} con las entregas y exámenes del planificador (solo los pendientes). */
@Component
public class ExamCalendarAdapter implements ExamCalendarPort {

    private final DeadlineRepositoryPort deadlines;

    public ExamCalendarAdapter(DeadlineRepositoryPort deadlines) {
        this.deadlines = deadlines;
    }

    @Override
    public boolean hasExamBetween(UUID userId, Instant from, Instant to) {
        return deadlines.findAll(userId, new DeadlineRepositoryPort.Query(from, to, null, true)).stream()
                .anyMatch(d -> d.type() == DeadlineType.EXAM);
    }
}
