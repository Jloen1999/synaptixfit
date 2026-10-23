package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Dependencias inválidas: inexistentes, a sí misma, cíclicas o con una condición imposible. */
public class InvalidMilestoneDependencyException extends BusinessRuleException {

    public InvalidMilestoneDependencyException(String message) {
        super("MILESTONE_DEPENDENCY_INVALID", message);
    }
}
