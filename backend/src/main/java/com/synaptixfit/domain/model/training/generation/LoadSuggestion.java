package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Propuesta de carga para hoy en un ejercicio de la sesión en vivo («Hoy prueba 42,5 kg (+5 %)»). La
 * calcula {@link LoadSuggestions} a partir de lo que se hizo la última vez; aceptarla solo cambia las
 * series que quedan de hoy, nunca la rutina.
 *
 * @param previous      lo que se hizo la última vez en la cifra que cambia
 * @param suggested     lo que se propone hoy en esa cifra
 * @param changePercent variación redondeada respecto a {@code previous} (nula si {@code previous} es 0)
 * @param lastRpe       esfuerzo percibido de aquella sesión
 * @param perSet        cifra propuesta para cada serie planificada (posición n-1 = serie n), en la unidad de
 *                      {@code metric}: en una pirámide cada serie se mueve en la misma proporción
 */
public record LoadSuggestion(UUID plannedExerciseId, UUID exerciseId, Metric metric, double previous,
                             double suggested, Integer changePercent, AdjustmentReason reason, int lastRpe,
                             Instant lastSessionAt, List<Double> perSet) {

    public LoadSuggestion {
        perSet = perSet == null ? List.of() : List.copyOf(perSet);
    }

    /** Cifra que cambia: la que la progresión mueve primero en ese ejercicio. */
    public enum Metric {
        WEIGHT,
        REPS,
        HOLD_SECONDS,
        DURATION_SECONDS,
        DISTANCE_METERS
    }

    public boolean increases() {
        return suggested > previous;
    }
}
