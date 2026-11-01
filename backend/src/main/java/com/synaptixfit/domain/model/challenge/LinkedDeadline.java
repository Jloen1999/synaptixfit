package com.synaptixfit.domain.model.challenge;

import java.time.Instant;

/**
 * Foto de solo lectura de la entrega o examen vinculado (de Planificador), cargada con el reto. La entrega
 * es la fuente de verdad de la tarea vinculada: su estado manda sobre el de la tarea (ADR 0028).
 */
public record LinkedDeadline(String title, Instant dueAt, boolean completed) {
}
