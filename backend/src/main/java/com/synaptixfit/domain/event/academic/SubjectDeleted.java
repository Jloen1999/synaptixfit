package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Una asignatura se va a borrar. Se publica justo antes del borrado físico (misma transacción)
 * porque {@code horarios_academicos} cae en cascada: el planificador borra antes sus bloques por
 * su caso de uso para restar su XP y publicar {@code StudyBlockCompletionChanged}.
 */
public record SubjectDeleted(UUID userId, UUID subjectId, Instant occurredAt) implements DomainEvent {
}
