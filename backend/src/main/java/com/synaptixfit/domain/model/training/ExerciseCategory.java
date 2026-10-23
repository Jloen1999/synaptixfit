package com.synaptixfit.domain.model.training;

/**
 * Tipo de ejercicio, más fino que {@link Modality}: permite buscar estiramientos, movilidad o
 * pliometría y elegir el calentamiento o la vuelta a la calma de una sesión. Los ejercicios sin
 * categoría guardada la deducen de su modalidad ({@link #of(Modality)}).
 */
public enum ExerciseCategory {
    STRENGTH,
    CALISTHENICS,
    OLYMPIC,
    ISOMETRIC,
    PLYOMETRICS,
    CARDIO,
    COMBAT,
    STRETCHING,
    MOBILITY,
    YOGA,
    PILATES,
    REHAB;

    public static ExerciseCategory of(Modality modality) {
        return switch (modality == null ? Modality.STRENGTH : modality) {
            case STRENGTH -> STRENGTH;
            case MOBILITY -> MOBILITY;
            case METABOLIC -> PLYOMETRICS;
            case AEROBIC -> CARDIO;
        };
    }

    /** Sirve para preparar el cuerpo antes de una sesión o soltarlo al acabar. */
    public boolean isWarmUpOrCoolDown() {
        return this == STRETCHING || this == MOBILITY || this == YOGA;
    }
}
