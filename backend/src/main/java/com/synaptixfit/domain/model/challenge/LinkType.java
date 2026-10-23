package com.synaptixfit.domain.model.challenge;

/** Tipo de elemento del planificador al que se vincula un reto o tarea. */
public enum LinkType {
    EXAM,
    DELIVERY,
    BLOCK;

    /** Los exámenes y entregas se sincronizan en ambos sentidos; los bloques no. */
    public boolean isDeadline() {
        return this != BLOCK;
    }
}
