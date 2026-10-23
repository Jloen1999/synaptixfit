package com.synaptixfit.domain.model.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Bloque propuesto por las sugerencias de planificación (no se guarda: el usuario lo acepta creando
 * el bloque).
 *
 * @param type {@link ActivityType#STUDY} o {@link ActivityType#SPORT}
 */
public record SuggestedBlock(ActivityType type, Instant start, Instant end, UUID subjectId, String subjectName,
                             UUID routineId, String routineName, String topic) {
}
