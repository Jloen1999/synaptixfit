package com.synaptixfit.domain.model.training;

import java.time.Instant;
import java.util.UUID;

/**
 * Mejor marca en un ejercicio: el mayor peso movido (con sus repeticiones) o, en ejercicios sin
 * carga, el mayor número de repeticiones en una serie. Lo calcula {@link PersonalRecords}.
 *
 * @param weightKg peso de la serie; nulo en ejercicios sin carga ({@link Kind#REPS})
 */
public record PersonalRecord(UUID exerciseId, String exerciseName, Kind kind, Double weightKg, int reps,
                             UUID sessionId, Instant achievedAt) {

    /** Qué se compara: el peso (con carga) o las repeticiones (peso corporal). */
    public enum Kind {
        WEIGHT,
        REPS
    }
}
