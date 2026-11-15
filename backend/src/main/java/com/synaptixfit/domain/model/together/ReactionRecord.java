package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Reacción fija de {@code authorId} a lo que sumó {@code recipientId} el día {@code day} en un reto con amigos
 * (ADR 0044). Una por persona y entrada: reaccionar otra vez la cambia.
 */
public record ReactionRecord(UUID challengeId, UUID recipientId, LocalDate day, UUID authorId, Reaction reaction,
                             Instant createdAt) {

    public ReactionRecord {
        Guard.notNull(challengeId, "challengeId");
        Guard.notNull(recipientId, "recipientId");
        Guard.notNull(day, "day");
        Guard.notNull(authorId, "authorId");
        Guard.notNull(reaction, "reaction");
        Guard.notNull(createdAt, "createdAt");
    }
}
