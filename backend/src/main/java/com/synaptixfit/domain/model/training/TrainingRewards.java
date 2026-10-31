package com.synaptixfit.domain.model.training;

/**
 * Experiencia que otorga el módulo de entrenamiento (valores heredados de la app anterior).
 *
 * <p>Sesión completada: {@code 50 + min(minutos, 90) + 5 * RPE}. Check-in diario: 20, solo el
 * primero de cada día.
 *
 * <p>Contra el farmeo: una sesión de menos de {@value #MIN_COUNTED_MINUTES} minutos se guarda pero no da XP
 * ni cuenta para retos, insignias ni racha (empezar y terminar en un segundo daba ~100 XP), y solo las
 * {@value #MAX_REWARDED_SESSIONS_PER_DAY} primeras sesiones de cada día dan XP.
 */
public final class TrainingRewards {

    public static final int SESSION_BASE_XP = 50;
    public static final int SESSION_MAX_MINUTES_XP = 90;
    public static final int XP_PER_RPE_POINT = 5;
    public static final int CHECK_IN_XP = 20;
    public static final int MIN_COUNTED_MINUTES = 10;
    public static final int MAX_REWARDED_SESSIONS_PER_DAY = 2;

    private TrainingRewards() {
    }

    /** ¿La sesión cuenta como entrenamiento (XP, retos, insignias y racha)? */
    public static boolean countsAsWorkout(int durationMinutes) {
        return durationMinutes >= MIN_COUNTED_MINUTES;
    }

    /**
     * XP de una sesión terminada; {@code rewardedToday} son las sesiones del mismo día que ya
     * contaron antes que esta.
     */
    public static int sessionXp(int durationMinutes, int rpe, int rewardedToday) {
        if (!countsAsWorkout(durationMinutes) || rewardedToday >= MAX_REWARDED_SESSIONS_PER_DAY) {
            return 0;
        }
        int minutes = Math.max(0, Math.min(durationMinutes, SESSION_MAX_MINUTES_XP));
        return SESSION_BASE_XP + minutes + rpe * XP_PER_RPE_POINT;
    }
}
