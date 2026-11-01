package com.synaptixfit.domain.model.training;

import java.util.List;

/**
 * Duración prevista de un ejercicio y de un día de rutina, para enseñar «≈ 45 min» antes de empezar
 * y «quedan ≈ 12 min» durante la sesión. Es una estimación: la duración que cuenta (carga, kcal) es
 * siempre el tiempo real de la sesión. Fórmula en {@code docs/01-architecture/formulas.md}.
 *
 * <ul>
 *   <li>Si el ejercicio ya se hizo, manda su duración real de la última vez ({@code realDurationSeconds},
 *       que guarda la sesión en vivo).</li>
 *   <li>Si no: {@code series × (trabajo + descanso)}. Trabajo de una serie = duración objetivo (cardio),
 *       o segundos de aguante (isométrico), o {@value #SECONDS_PER_REP} s por repetición. El descanso
 *       tras la última serie cubre el cambio al siguiente ejercicio.</li>
 * </ul>
 */
public final class SessionDurationEstimate {

    /** Tempo medio de una repetición controlada (≈ 1 s concéntrica, 2 s excéntrica). */
    public static final int SECONDS_PER_REP = 3;

    private SessionDurationEstimate() {
    }

    /** Segundos previstos para un ejercicio planificado. */
    public static int exerciseSeconds(ExerciseParameters p, Integer realDurationSeconds) {
        if (realDurationSeconds != null && realDurationSeconds > 0) {
            return realDurationSeconds;
        }
        int sets = Math.max(1, p.sets());
        int work;
        if (p.targetDurationSeconds() != null && p.targetDurationSeconds() > 0) {
            work = p.targetDurationSeconds();
        } else if (p.isometricSeconds() != null && p.isometricSeconds() > 0) {
            work = p.isometricSeconds();
        } else {
            work = Math.max(1, p.reps()) * SECONDS_PER_REP;
        }
        return sets * (work + Math.max(0, p.restSeconds()));
    }

    public static int exerciseSeconds(PlannedExercise p) {
        return exerciseSeconds(p.parameters(), p.realDurationSeconds());
    }

    /** Minutos previstos de un día (redondeado hacia arriba; 0 sin ejercicios). */
    public static int dayMinutes(List<PlannedExercise> exercises) {
        int seconds = exercises.stream().mapToInt(SessionDurationEstimate::exerciseSeconds).sum();
        return (seconds + 59) / 60;
    }
}
