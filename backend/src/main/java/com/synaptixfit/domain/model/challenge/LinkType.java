package com.synaptixfit.domain.model.challenge;

/**
 * Elemento del planificador al que se vincula un reto o tarea: un examen o una entrega. Los bloques de
 * estudio no son un vínculo: se asignan a una tarea desde el editor de bloques (ADR 0028).
 */
public enum LinkType {
    EXAM,
    DELIVERY
}
