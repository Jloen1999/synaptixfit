package com.synaptixfit.domain.model.challenge;

/**
 * Esfuerzo de un reto o tarea. Regla heredada de {@code xp_por_dificultad}: baja 20, media 40,
 * alta 70 puntos de experiencia.
 */
public enum Difficulty {
    LOW(20),
    MEDIUM(40),
    HIGH(70);

    private final int xp;

    Difficulty(int xp) {
        this.xp = xp;
    }

    /** Experiencia que otorga completar un elemento de esta dificultad. */
    public int xp() {
        return xp;
    }
}
