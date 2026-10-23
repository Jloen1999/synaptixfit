package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.UUID;

/** Vínculo de un reto o tarea con una entrega, examen o bloque del calendario. */
public record ChallengeLink(LinkType type, UUID entityId) {

    public ChallengeLink {
        Guard.notNull(type, "linkedEntityType");
        Guard.notNull(entityId, "linkedEntityId");
    }
}
