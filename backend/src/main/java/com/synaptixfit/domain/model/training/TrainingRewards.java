package com.synaptixfit.domain.model.training;

/**
 * Experiencia que otorga el módulo de entrenamiento (valores heredados de la app anterior).
 *
 * <p>Sesión completada: {@code 50 + min(minutos, 90) + 5 * RPE}. Check-in diario: 20, solo el
 * primero de cada día.
 */
public final class TrainingRewards {

    public static final int SESSION_BASE_XP = 50;
    public static final int SESSION_MAX_MINUTES_XP = 90;
    public static final int XP_PER_RPE_POINT = 5;
    public static final int CHECK_IN_XP = 20;

    private TrainingRewards() {
    }

    public static int sessionXp(int durationMinutes, int rpe) {
        int minutes = Math.max(0, Math.min(durationMinutes, SESSION_MAX_MINUTES_XP));
        return SESSION_BASE_XP + minutes + rpe * XP_PER_RPE_POINT;
    }
}
