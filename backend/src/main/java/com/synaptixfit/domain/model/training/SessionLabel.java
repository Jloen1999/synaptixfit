package com.synaptixfit.domain.model.training;

import java.util.UUID;

/**
 * Nombre legible de una sesión: rutina y día que se entrenó («Tracción: dominadas y bíceps»). Si el
 * día no tiene nombre se queda nulo y el cliente muestra «Día N»; en sesiones libres o si la rutina
 * se borró, todo es nulo.
 */
public record SessionLabel(UUID sessionId, String routineName, String dayName, Integer dayNumber,
                           Integer weekNumber) {
}
