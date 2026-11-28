package com.synaptixfit.domain.model.wod;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Collection;
import java.util.Comparator;
import java.util.Optional;
import java.util.UUID;

/**
 * Marca de un WOD (ADR 0069).
 *
 * @param value           segundos ({@code TIME}), rondas ({@code ROUNDS_REPS}), repeticiones ({@code REPS}) o kg
 *                        enteros ({@code LOAD})
 * @param extraReps       repeticiones de la ronda sin acabar; solo en {@code ROUNDS_REPS}
 * @param capped          se acabó el límite sin terminar (solo «por tiempo»): cuenta por debajo de cualquier tiempo
 * @param durationSeconds lo que duró de verdad (cronómetro), para la actividad apuntada
 * @param blockId         evento del calendario de su actividad
 */
public record WodResult(UUID id, UUID wodId, UUID userId, WodDivision division, WodScoreType scoreType, int value,
                        Integer extraReps, boolean capped, int durationSeconds, UUID blockId, Instant performedAt) {

    public static final int MAX_VALUE = 100_000;

    public WodResult {
        Guard.notNull(division, "division");
        Guard.notNull(scoreType, "scoreType");
        Guard.range(value, "value", scoreType == WodScoreType.TIME ? 1 : 0, MAX_VALUE);
        if (scoreType == WodScoreType.ROUNDS_REPS) {
            extraReps = extraReps == null ? 0 : Guard.range(extraReps, "extraReps", 0, MAX_VALUE);
        } else {
            extraReps = null;
        }
        if (capped && scoreType != WodScoreType.REPS) {
            throw new FieldValidationException("capped", "INVALID", "a capped result counts reps");
        }
    }

    /**
     * ¿Es mejor que la otra? Terminar gana a quedarse en el límite; en tiempo gana el menor; en lo demás, el mayor
     * (rondas y, si empatan, repeticiones). Marcas de distinto tipo no se comparan.
     */
    public boolean beats(WodResult other) {
        if (capped != other.capped) {
            return !capped;
        }
        if (scoreType != other.scoreType) {
            return false;
        }
        if (scoreType == WodScoreType.TIME) {
            return value < other.value;
        }
        if (value != other.value) {
            return value > other.value;
        }
        return extraReps != null && other.extraReps != null && extraReps > other.extraReps;
    }

    /**
     * La mejor de unas marcas del mismo WOD y la misma división. La carga de la parte de fuerza no compite con la
     * marca del WOD; a igualdad, la primera que se hizo.
     */
    public static Optional<WodResult> best(Collection<WodResult> results) {
        return results.stream()
                .filter(r -> r.scoreType() != WodScoreType.LOAD)
                .sorted(Comparator.comparing(WodResult::performedAt))
                .reduce((best, next) -> next.beats(best) ? next : best);
    }
}
