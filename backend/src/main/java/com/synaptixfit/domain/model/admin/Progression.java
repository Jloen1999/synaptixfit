package com.synaptixfit.domain.model.admin;

/** Cálculos de progresión para el panel (la regla de niveles vive en {@code User}). */
public final class Progression {

    private Progression() {
    }

    /**
     * Experiencia total acumulada: los umbrales completados (100·k para cada nivel k anterior al
     * actual) más la experiencia del nivel actual.
     */
    public static long totalXp(int level, int levelXp) {
        long lvl = Math.max(1, level);
        return 50L * lvl * (lvl - 1) + Math.max(0, levelXp);
    }
}
