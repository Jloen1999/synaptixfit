package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de entregas y exámenes ({@code entregas_examenes}). */
public interface DeadlineRepositoryPort {

    /**
     * Filtro de consulta; los campos nulos no filtran.
     *
     * @param from        fecha límite desde (incluida)
     * @param to          fecha límite hasta (excluida)
     * @param pendingOnly solo las no completadas
     */
    record Query(Instant from, Instant to, UUID subjectId, boolean pendingOnly) {
    }

    Deadline save(Deadline deadline);

    Optional<Deadline> findById(UUID id);

    void delete(UUID id);

    /** Página ordenada por fecha límite ascendente. */
    PageResult<Deadline> find(UUID userId, Query query, PageRequest page);

    /** Todas las que cumplen el filtro, ordenadas por fecha límite. */
    List<Deadline> findAll(UUID userId, Query query);

    Map<String, Deadline> findByIcsUids(UUID userId, Collection<String> icsUids);
}
