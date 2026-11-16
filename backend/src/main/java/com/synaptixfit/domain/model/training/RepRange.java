package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;

/**
 * Rango de repeticiones de un ejercicio («8-12») y cuántas deberían sobrar en cada serie ({@code reserve}, las
 * repeticiones en reserva: «te deben sobrar 2»). Lo traen las plantillas (ADR 0054) y lo usa la doble progresión
 * ({@code ProgressionCalculator}): se sube peso cuando todas las series llegan a {@code max}.
 *
 * @param reserve repeticiones que deberían sobrar (0-5); nulo si el ejercicio no lo pide (movilidad)
 */
public record RepRange(int min, int max, Integer reserve) {

    public static final int MAX_RESERVE = 5;

    public RepRange {
        Guard.range(min, "repMin", ExerciseParameters.MIN_REPS, ExerciseParameters.MAX_REPS);
        Guard.range(max, "repMax", min, ExerciseParameters.MAX_REPS);
        if (reserve != null) {
            Guard.range(reserve, "repsInReserve", 0, MAX_RESERVE);
        }
    }

    /** Rango con los valores que lleguen; nulo si falta el mínimo o el máximo (ejercicio sin rango). */
    public static RepRange of(Integer min, Integer max, Integer reserve) {
        return min == null || max == null ? null : new RepRange(min, max, reserve);
    }

    /** Rango guardado o nulo si falta o no es válido: los datos guardados nunca rompen la lectura. */
    public static RepRange ofStored(Integer min, Integer max, Integer reserve) {
        boolean valid = min != null && max != null && min >= ExerciseParameters.MIN_REPS && max >= min
                && max <= ExerciseParameters.MAX_REPS && (reserve == null || reserve >= 0 && reserve <= MAX_RESERVE);
        return valid ? new RepRange(min, max, reserve) : null;
    }

    /** Las repeticiones ajustadas al rango. */
    public int clamp(int reps) {
        return Math.max(min, Math.min(max, reps));
    }

    /**
     * Esfuerzo de sesión (RPE 1-10) que corresponde a dejar {@code reserve} repeticiones: RPE ≈ 10 − reserva
     * (Zourdos 2016). Sin reserva pedida se toma 2 (RPE 8), lo habitual en las plantillas.
     */
    public double targetRpe() {
        return 10 - (reserve == null ? 2 : reserve);
    }
}
