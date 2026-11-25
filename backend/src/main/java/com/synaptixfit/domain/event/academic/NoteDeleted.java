package com.synaptixfit.domain.event.academic;

import com.synaptixfit.domain.event.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/** Un apunte se ha borrado: lo que lo enlaza en otros módulos (su publicación en el muro, ADR 0064) se retira. */
public record NoteDeleted(UUID userId, UUID noteId, Instant occurredAt) implements DomainEvent {
}
