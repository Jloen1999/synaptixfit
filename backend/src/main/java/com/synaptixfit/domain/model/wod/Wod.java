package com.synaptixfit.domain.model.wod;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * WOD de una persona (ADR 0069): lo que dice su pizarra un día concreto.
 *
 * @param templateCode plantilla de ejemplo de la que salió (opcional)
 */
public record Wod(UUID id, UUID userId, LocalDate date, String templateCode, WodDefinition definition,
                  Instant createdAt, Instant updatedAt) {

    public Wod {
        Guard.notNull(id, "id");
        Guard.notNull(userId, "userId");
        Guard.notNull(date, "date");
        Guard.notNull(definition, "definition");
        templateCode = templateCode == null || templateCode.isBlank() ? null : templateCode;
    }

    /** El mismo WOD con otra pizarra u otro día; deja de ser «de plantilla» si cambia lo que se hace. */
    public Wod changed(LocalDate newDate, WodDefinition newDefinition, Instant now) {
        boolean same = newDefinition.signature().equals(definition.signature());
        return new Wod(id, userId, newDate == null ? date : newDate, same ? templateCode : null, newDefinition,
                createdAt, now);
    }
}
