package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** Reto sin tareas vinculado a una entrega o examen: se completa solo cuando se completa ese elemento (ADR 0028). */
public class ChallengeLinkedException extends BusinessRuleException {

    public ChallengeLinkedException(UUID id) {
        super("CHALLENGE_LINKED", "challenge " + id + " is completed by its linked deadline");
    }
}
