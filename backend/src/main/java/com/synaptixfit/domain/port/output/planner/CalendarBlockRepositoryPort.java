package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de los bloques del calendario ({@code horarios_academicos}). */
public interface CalendarBlockRepositoryPort {

    CalendarBlock save(CalendarBlock block);

    List<CalendarBlock> saveAll(List<CalendarBlock> blocks);

    Optional<CalendarBlock> findById(UUID id);

    /**
     * Como {@link #findById}, bloqueando la fila hasta el fin de la transacción: marcar a mano y la tarea que da
     * las clases por asistidas no se pisan (ADR 0029).
     */
    Optional<CalendarBlock> findByIdForUpdate(UUID id);

    void delete(UUID id);

    /** Bloques del usuario que se solapan con [from, to), ordenados por inicio. Filtro opcional por asignatura. */
    List<CalendarBlock> findOverlapping(UUID userId, Instant from, Instant to, UUID subjectId);

    /** Bloques del usuario con esos {@code ics_uid}, indexados por uid. */
    Map<String, CalendarBlock> findByIcsUids(UUID userId, Collection<String> icsUids);

    /** Bloques de repaso no completados de ese material (de cualquier fecha), por inicio ascendente. */
    List<CalendarBlock> findPendingReviews(UUID userId, UUID studyMaterialId);

    /** Todos los bloques del usuario de esa asignatura. */
    List<CalendarBlock> findBySubject(UUID userId, UUID subjectId);

    /** Todos los bloques del usuario enlazados a esa rutina, por inicio ascendente. */
    List<CalendarBlock> findByRoutine(UUID userId, UUID routineId);

    /** Todos los bloques del usuario enlazados a esos días de rutina, por inicio ascendente. */
    List<CalendarBlock> findByRoutineDays(UUID userId, Collection<UUID> routineDayIds);

    /**
     * Clases de cualquier usuario sin completar ni marcar «No fui» que terminaron en [from, to), por fin
     * ascendente: las que se dan por asistidas solas (ADR 0029).
     */
    List<CalendarBlock> findClassesToAttend(Instant from, Instant to);
}
