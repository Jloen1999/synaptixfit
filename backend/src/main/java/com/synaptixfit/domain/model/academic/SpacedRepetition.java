package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;

/**
 * Algoritmo SM-2 (SuperMemo 2) en escala 0-5.
 *
 * <ul>
 *   <li>Fallo si la calidad <b>real</b> es menor que 3: se reinician las repeticiones y el intervalo
 *       pasa a 1 día (estado «necesita repaso» si es 0 o 1, «en progreso» si no). El ajuste por fatiga
 *       nunca convierte un fallo en acierto: solo suaviza la penalización del factor de facilidad.</li>
 *   <li>Acierto: intervalos 1 y 6 días para las dos primeras repeticiones y después
 *       {@code ceil(intervalo_anterior * EF)} con el EF previo. Con 3 o más repeticiones
 *       seguidas el material pasa a «dominado».</li>
 *   <li>Factor de facilidad: {@code EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))} con la
 *       calidad ajustada sin redondear (la fracción del ajuste por fatiga cuenta) y acotado a [1.3, 3.0].</li>
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

    /** Repaso sin ajuste por fatiga: la calidad real y la ajustada coinciden. */
    public static Result next(int quality, int previousIntervalDays, double easeFactor, int repetitions) {
        return next(quality, quality, previousIntervalDays, easeFactor, repetitions);
    }

    public static Result next(int realQuality, double adjustedQuality, int previousIntervalDays, double easeFactor,
                              int repetitions) {
        Guard.range(realQuality, "quality", 0, 5);
        Guard.range(adjustedQuality, "quality", 0, 5);
        double ease = easeFactor <= 0 ? INITIAL_EASE : easeFactor;
        int interval;
        int newRepetitions;
        MasteryState state;
        boolean failed = realQuality < 3;
        if (failed) {
            newRepetitions = 0;
            interval = 1;
            state = realQuality <= 1 ? MasteryState.NEEDS_REVIEW : MasteryState.IN_PROGRESS;
        } else {
            interval = switch (Math.max(0, repetitions)) {
                case 0 -> 1;
                case 1 -> 6;
                default -> Math.max(1, (int) Math.ceil(Math.max(1, previousIntervalDays) * ease));
            };
            newRepetitions = Math.max(0, repetitions) + 1;
            state = newRepetitions >= 3 ? MasteryState.MASTERED : MasteryState.IN_PROGRESS;
        }
        double distance = 5 - adjustedQuality;
        double newEase = ease + (0.1 - distance * (0.08 + distance * 0.02));
        newEase = Math.max(MIN_EASE, Math.min(MAX_EASE, newEase));
        return new Result(interval, newEase, newRepetitions, state, failed);
    }
}
