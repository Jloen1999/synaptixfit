package com.synaptixfit.domain.model.challenge;

/**
 * Filtros del listado de retos.
 *
 * @param status    estado (null = todos)
 * @param type      ámbito (null = todos)
 * @param withTasks true = solo con tareas, false = solo sin tareas, null = todos
 * @param text      texto a buscar en el título (null = sin filtro)
 */
public record ChallengeQuery(ChallengeStatus status, ChallengeType type, Boolean withTasks, String text) {

    public ChallengeQuery {
        text = text == null || text.isBlank() ? null : text.strip();
    }
}
