package com.synaptixfit.domain.model.challenge;

import java.time.Instant;

/**
 * Foto de solo lectura de lo que completa una tarea vinculada: una entrega o examen (de Planificador) o un día
 * de rutina (de Entrenamiento, ADR 0032). Su estado manda sobre el de la tarea (ADR 0028).
 *
 * @param dueAt      cuándo vence la entrega; nulo en un día de rutina (no tiene fecha límite)
 * @param weekNumber semana del día de rutina (nula en entregas)
 * @param dayNumber  día de la semana del día de rutina, 1 = lunes (nulo en entregas)
 */
public record LinkedDeadline(String title, Instant dueAt, boolean completed, Integer weekNumber,
                             Integer dayNumber) {

    /** Entrega o examen. */
    public LinkedDeadline(String title, Instant dueAt, boolean completed) {
        this(title, dueAt, completed, null, null);
    }
}
