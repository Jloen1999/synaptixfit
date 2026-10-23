package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.UUID;

/**
 * Entregas del usuario por fecha límite ascendente, con filtros opcionales.
 */
public interface GetDeadlinesUseCase {

    /**
     * @param upcomingOnly solo las pendientes con fecha límite desde hoy (00:00 local)
     * @param from         fecha límite desde (incluida)
     * @param to           fecha límite hasta (excluida)
     */
    record Query(UUID userId, Instant from, Instant to, UUID subjectId, boolean upcomingOnly, PageRequest page) {
    }

    PageResult<Deadline> getDeadlines(Query query);
}
