package com.synaptixfit.domain.model.planner;

import java.util.UUID;

/**
 * Asignatura del usuario vista desde el planificador (la gestiona el módulo académico).
 *
 * @param perceivedDifficulty dificultad percibida 1-5
 * @param icsUrl              URL del calendario ICS configurada en la asignatura (puede ser nula)
 */
public record SubjectRef(UUID id, String name, String code, int perceivedDifficulty, int credits, String icsUrl) {
}
