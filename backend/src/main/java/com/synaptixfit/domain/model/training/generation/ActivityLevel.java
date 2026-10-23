package com.synaptixfit.domain.model.training.generation;

/** Nivel de actividad física declarado en el perfil de bienestar. */
public enum ActivityLevel {
    SEDENTARY(0),
    LIGHT(1),
    MODERATE(2),
    HIGH(3);

    private final int rank;

    ActivityLevel(int rank) {
        this.rank = rank;
    }

    public int rank() {
        return rank;
    }
}
