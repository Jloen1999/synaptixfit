package com.synaptixfit.domain.model.wod;

/**
 * Formato de un WOD (ADR 0069) y cómo se apunta su marca: por tiempo (cuanto menos, mejor), AMRAP (rondas y
 * repeticiones en un tiempo fijo), EMOM (cada minuto) y Tabata (8 × 20 s de trabajo y 10 s de descanso).
 */
public enum WodFormat {
    FOR_TIME,
    AMRAP,
    EMOM,
    TABATA;

    /** Tabata dura siempre lo mismo: 8 × (20 s + 10 s). */
    public static final int TABATA_ROUNDS = 8;
    public static final int TABATA_SECONDS = 240;

    /**
     * Qué se apunta: en «por tiempo», el tiempo o, si se acabó el límite sin terminar, las repeticiones hechas; en
     * AMRAP, rondas y repeticiones; en EMOM y Tabata, repeticiones.
     */
    public WodScoreType scoreType(boolean capped) {
        return switch (this) {
            case FOR_TIME -> capped ? WodScoreType.REPS : WodScoreType.TIME;
            case AMRAP -> WodScoreType.ROUNDS_REPS;
            case EMOM, TABATA -> WodScoreType.REPS;
        };
    }
}
