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
     * @param upcomingOnly   solo las pendientes con fecha límite desde hoy (00:00 local)
     * @param includeOverdue con {@code upcomingOnly}, también las vencidas sin completar de los
     *                       últimos 30 días (primero, por fecha): la lista «Pendientes»
     * @param from           fecha límite desde (incluida)
     * @param to             fecha límite hasta (excluida)
     */
    record Query(UUID userId, Instant from, Instant to, UUID subjectId, boolean upcomingOnly,
                 boolean includeOverdue, PageRequest page) {

        public Query(UUID userId, Instant from, Instant to, UUID subjectId, boolean upcomingOnly, PageRequest page) {
            this(userId, from, to, subjectId, upcomingOnly, false, page);
        }
    }

    PageResult<Deadline> getDeadlines(Query query);
}
