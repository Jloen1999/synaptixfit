package com.synaptixfit.domain.model.training;

import java.util.ArrayList;
import java.util.List;

/**
 * Duración prevista de un ejercicio y de un día de rutina, para enseñar «≈ 45 min» antes de empezar
 * y «te quedan ≈ 12 min» durante la sesión. Es una estimación: la duración que cuenta (carga, kcal) es
 * siempre el tiempo real de la sesión. Fórmula en {@code docs/01-architecture/formulas.md} (ADR 0048).
 *
 * <ul>
 *   <li>Base, la de siempre: {@code series × (trabajo + descanso)}. Trabajo de una serie = duración objetivo
 *       (cardio), o segundos de aguante (isométrico), o {@value #SECONDS_PER_REP} s por repetición. El descanso
 *       tras la última serie cubre el cambio al siguiente ejercicio.</li>
 *   <li>Si el ejercicio ya se hizo, aprende de las últimas veces (como mucho
 *       {@value PlannedExercise#RECENT_DURATIONS}): cada duración real se acota a
 *       [{@value #MIN_SHARE_OF_BASE} × base, {@value #MAX_SHARE_OF_BASE} × base] y con 1 dato manda ese, con 2 la
 *       media y con 3 la mediana. Así una sesión olvidada abierta no infla la estimación y un día raro no cuenta.</li>
 * </ul>
 */
public final class SessionDurationEstimate {

    /** Tempo medio de una repetición controlada (≈ 1 s concéntrica, 2 s excéntrica). */
    public static final int SECONDS_PER_REP = 3;

    /**
     * Tope inferior de una duración real frente a la base: hacerlo en menos de la mitad suele ser marcar las series
     * de golpe al final, no entrenar más rápido.
     */
    public static final double MIN_SHARE_OF_BASE = 0.5;

    /**
     * Tope superior: más de 2,5 veces la base es casi siempre una sesión que se quedó abierta o una pausa larga sin
     * marcar, no el ritmo real de la persona.
     */
    public static final double MAX_SHARE_OF_BASE = 2.5;

    private SessionDurationEstimate() {
    }

    /** Segundos de la fórmula de siempre (sin datos reales). */
    public static int baseSeconds(ExerciseParameters p) {
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

    /**
     * Duración aprendida de las últimas veces ({@code recentSeconds}, de la más antigua a la más reciente): cada una
     * acotada a la base y después 1 dato → ese, 2 → media, 3 → mediana. Nula si no hay datos.
     */
    public static Integer learnedSeconds(ExerciseParameters p, List<Integer> recentSeconds) {
        List<Integer> valid = recentSeconds == null ? List.of()
                : recentSeconds.stream().filter(s -> s != null && s > 0).toList();
        if (valid.isEmpty()) {
            return null;
        }
        int base = baseSeconds(p);
        long min = Math.round(base * MIN_SHARE_OF_BASE);
        long max = Math.round(base * MAX_SHARE_OF_BASE);
        // Solo cuentan las más recientes (el modelo ya guarda como mucho tres).
        int from = Math.max(0, valid.size() - PlannedExercise.RECENT_DURATIONS);
        List<Long> bounded = new ArrayList<>();
        for (int s : valid.subList(from, valid.size())) {
            bounded.add(Math.clamp(s, min, max));
        }
        bounded.sort(Long::compare);
        return switch (bounded.size()) {
            case 1 -> (int) (long) bounded.getFirst();
            case 2 -> (int) Math.round((bounded.get(0) + bounded.get(1)) / 2.0);
            default -> (int) (long) bounded.get(1);
        };
    }

    /** Segundos previstos para un ejercicio: lo aprendido si ya se hizo; si no, la base. */
    public static int exerciseSeconds(ExerciseParameters p, List<Integer> recentSeconds) {
        Integer learned = learnedSeconds(p, recentSeconds);
        return learned != null ? learned : baseSeconds(p);
    }

    public static int exerciseSeconds(PlannedExercise p) {
        return p.estimatedSeconds();
    }

    /** Minutos previstos de un día (redondeado hacia arriba; 0 sin ejercicios). */
    public static int dayMinutes(List<PlannedExercise> exercises) {
        int seconds = exercises.stream().mapToInt(SessionDurationEstimate::exerciseSeconds).sum();
        return (seconds + 59) / 60;
    }
}
