package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** Tarea vinculada a una entrega, un examen o bloques del calendario: la completa ese elemento, no un toque (ADR 0028). */
public class MilestoneLinkedException extends BusinessRuleException {

    public MilestoneLinkedException(UUID id) {
        super("MILESTONE_LINKED", "milestone " + id + " is completed by its linked deadline or study blocks");
    }
}
