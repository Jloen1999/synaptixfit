package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.SubjectAgenda;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Clases y entregas futuras de las asignaturas de una persona, leídas del planificador para la tarjeta de asignatura
 * ({@link SubjectAgenda}, ADR 0036).
 */
public interface SubjectAgendaPort {

    /** Clases (bloques de tipo clase a los que no ha faltado) que empiezan en [{@code from}, {@code to}). */
    Map<UUID, List<SubjectAgenda.ClassSlot>> upcomingClasses(UUID userId, List<UUID> subjectIds, Instant from,
                                                             Instant to);

    /** Entregas y exámenes sin hacer que vencen desde {@code from}. */
    Map<UUID, List<SubjectAgenda.Deadline>> pendingDeadlines(UUID userId, List<UUID> subjectIds, Instant from);
}
