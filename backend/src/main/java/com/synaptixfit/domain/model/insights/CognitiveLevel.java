package com.synaptixfit.domain.model.insights;

/**
 * Nivel en palabras de la carga cognitiva y de la atención de {@link CognitiveState} («Tu equilibrio», Progreso). Los
 * umbrales estaban en el cliente; desde el ADR 0039 los decide el servidor y la app solo pone el texto y el color.
 */
public enum CognitiveLevel {
    LOW,
    MODERATE,
    HIGH,
    CRITICAL;

    /** Carga: baja &lt; 0,3 ≤ moderada &lt; 0,6 ≤ alta &lt; 0,8 ≤ crítica (0,8 = 4 h seguidas, ver formulas.md). */
    static final double MODERATE_LOAD = 0.3;
    static final double HIGH_LOAD = 0.6;
    static final double CRITICAL_LOAD = 0.8;

    /** Atención: baja &lt; 0,4 ≤ moderada &lt; 0,7 ≤ alta (0,5 a los 52 min de trabajo seguido). */
    static final double MODERATE_ATTENTION = 0.4;
    static final double HIGH_ATTENTION = 0.7;

    public static CognitiveLevel ofLoad(double load) {
        if (load < MODERATE_LOAD) {
            return LOW;
        }
        if (load < HIGH_LOAD) {
            return MODERATE;
        }
        return load < CRITICAL_LOAD ? HIGH : CRITICAL;
    }

    /** La atención no tiene nivel crítico: más alta es mejor. */
    public static CognitiveLevel ofAttention(double attention) {
        if (attention >= HIGH_ATTENTION) {
            return HIGH;
        }
        return attention >= MODERATE_ATTENTION ? MODERATE : LOW;
    }
}
