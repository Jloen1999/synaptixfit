package com.synaptixfit.domain.model.training;

/**
 * Por qué una sesión terminada no dio XP. Lo decide {@link TrainingRewards}; el cliente solo lo
 * explica («+0 XP: sesión de menos de 10 min»).
 */
public enum SessionXpWithheld {
    /** Duró menos de {@link TrainingRewards#MIN_COUNTED_MINUTES} minutos: no cuenta como entrenamiento. */
    SHORT_SESSION,
    /** Ese día ya dieron XP {@link TrainingRewards#MAX_REWARDED_SESSIONS_PER_DAY} sesiones. */
    DAILY_LIMIT
}
