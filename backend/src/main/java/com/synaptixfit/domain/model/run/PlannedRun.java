package com.synaptixfit.domain.model.run;

import java.time.Instant;
import java.util.UUID;

/**
 * Evento del calendario (tipo Entreno) con un entreno de carrera, aún por hacer: lo que la pantalla Correr enseña
 * como «Hoy toca…» para empezarlo con el GPS. Al grabarlo, el evento queda hecho.
 */
public record PlannedRun(UUID blockId, UUID workoutId, String workoutName, Instant start, Instant end) {
}
