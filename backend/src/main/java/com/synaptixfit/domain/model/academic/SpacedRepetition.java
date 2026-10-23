package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;

/**
 * Algoritmo SM-2 (SuperMemo 2) en escala 0-5 con calidad continua.
 *
 * <ul>
 *   <li>Fallo si {@code round(q) < 3}: se reinician las repeticiones y el intervalo pasa a 1 día
 *       (estado «necesita repaso» si {@code round(q) <= 1}, «en progreso» si no).</li>
 *   <li>Acierto: intervalos 1 y 6 días para las dos primeras repeticiones y después
 *       {@code ceil(intervalo_anterior * EF)} con el EF previo. Con 3 o más repeticiones
 *       seguidas el material pasa a «dominado».</li>
 *   <li>Factor de facilidad: {@code EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))} con la
 *       calidad sin redondear (la fracción del ajuste por fatiga cuenta) y acotado a [1.3, 3.0].</li>
 * </ul>
 */
public final class SpacedRepetition {

    public static final double MIN_EASE = 1.3;
    public static final double MAX_EASE = 3.0;
    public static final double INITIAL_EASE = 2.5;

    private SpacedRepetition() {
    }

    /** Resultado de aplicar un repaso. */
    public record Result(int intervalDays, double easeFactor, int repetitions, MasteryState masteryState,
                         boolean failed) {
    }

    public static Result next(double quality, int previousIntervalDays, double easeFactor, int repetitions) {
        Guard.range(quality, "quality", 0, 5);
        double ease = easeFactor <= 0 ? INITIAL_EASE : easeFactor;
        int discrete = (int) Math.round(quality);
        int interval;
        int newRepetitions;
        MasteryState state;
        boolean failed = discrete < 3;
        if (failed) {
            newRepetitions = 0;
            interval = 1;
            state = discrete <= 1 ? MasteryState.NEEDS_REVIEW : MasteryState.IN_PROGRESS;
        } else {
            interval = switch (Math.max(0, repetitions)) {
                case 0 -> 1;
                case 1 -> 6;
                default -> Math.max(1, (int) Math.ceil(Math.max(1, previousIntervalDays) * ease));
            };
            newRepetitions = Math.max(0, repetitions) + 1;
            state = newRepetitions >= 3 ? MasteryState.MASTERED : MasteryState.IN_PROGRESS;
        }
        double distance = 5 - quality;
        double newEase = ease + (0.1 - distance * (0.08 + distance * 0.02));
        newEase = Math.max(MIN_EASE, Math.min(MAX_EASE, newEase));
        return new Result(interval, newEase, newRepetitions, state, failed);
    }
}
