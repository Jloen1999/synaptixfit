package com.synaptixfit.domain.model.neuro;

import java.util.List;

/**
 * Fórmula 2 (v2, recalibrada): carga cognitiva del día y capacidad atencional. Documentación y
 * fuentes en {@code docs/01-architecture/formulas.md} y ADR 0011.
 *
 * <pre>
 * Esfuerzo de un bloque     e_i = D_i · μ_i                         (minutos equivalentes)
 * Esfuerzo acumulado        E_i = E_(i-1) · e^(-λ·R_i) + e_i        (el descanso recupera lo anterior)
 * Carga del día             C   = 1 - e^(-E_n / τ)                  (satura, nunca llega a 1)
 * Capacidad atencional      A(t) = A0 · e^(-β·t)                    (t = minutos seguidos)
 * </pre>
 *
 * <ul>
 *   <li>τ = 240 / ln 5 ≈ 149 min: 4 h de estudio exigente dan C = 0,8, el umbral «crítico». Unas 4 h
 *       al día es el máximo sostenible de práctica deliberada (Ericsson, Krampe y Tesch-Römer, 1993).
 *       La curva saturante sigue el patrón de las escalas de esfuerzo diario de aplicaciones como
 *       Whoop: cada minuto extra pesa menos en la escala cuanto más cargado está el día.</li>
 *   <li>λ = ln 2 / 90: la carga acumulada se reduce a la mitad tras 90 min de descanso (un ciclo
 *       ultradiano, Kleitman). Es una calibración, no una medida: no hay un dato único de
 *       recuperación de la fatiga mental.</li>
 *   <li>β = ln 2 / 52: la atención baja a la mitad tras 52 min seguidos, el ciclo de trabajo de los
 *       usuarios más productivos medido por la aplicación DeskTime (2014).</li>
 * </ul>
 *
 * <p>La versión anterior sumaba {@code (1 - e^(-0,1·D))·μ} por bloque: un solo bloque de 25 min ya
 * daba 0,92 («crítica»), así que la escala no distinguía 25 min de 4 h.
 */
public final class CognitiveLoad {

    /** Minutos equivalentes de estudio exigente que el día aguanta antes de la zona crítica. */
    static final double DAILY_CAPACITY_MINUTES = 240;

    /** Carga a la que se llega con {@link #DAILY_CAPACITY_MINUTES}: el umbral «crítico». */
    static final double CRITICAL_LOAD = 0.8;

    /** Constante de saturación: {@code 1 - e^(-240/τ) = 0,8}. */
    static final double TAU = DAILY_CAPACITY_MINUTES / Math.log(1 / (1 - CRITICAL_LOAD));

    /** Recuperación durante el descanso (semivida de 90 min). */
    static final double LAMBDA = Math.log(2) / 90;

    /** Caída de la atención con el trabajo continuo (mitad a los 52 min). */
    static final double BETA = Math.log(2) / 52;

    private CognitiveLoad() {
    }

    /** Carga del día (0-1) con los bloques en orden cronológico. */
    public static double accumulated(List<StudyBlockLoad> blocks) {
        double effort = 0;
        for (StudyBlockLoad b : blocks) {
            effort = effort * Math.exp(-LAMBDA * b.restBeforeMinutes()) + b.durationMinutes() * b.difficulty();
        }
        return clamp01(1 - Math.exp(-effort / TAU));
    }

    /** Capacidad atencional restante tras {@code minutes} de trabajo continuo. */
    public static double attentionCapacity(double initialCapacity, int minutes) {
        if (minutes <= 0) {
            return initialCapacity;
        }
        return initialCapacity * Math.exp(-BETA * minutes);
    }

    /** Multiplicador a partir de la dificultad percibida 1-5 de una asignatura. */
    public static double difficultyMultiplier(int perceivedDifficulty) {
        if (perceivedDifficulty >= 4) {
            return 1.8;
        }
        return perceivedDifficulty == 3 ? 1.3 : 1.0;
    }

    private static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
