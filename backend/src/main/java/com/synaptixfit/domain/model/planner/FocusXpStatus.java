package com.synaptixfit.domain.model.planner;

/**
 * Por qué una fase Pomodoro dio o no dio experiencia ({@link FocusRewards#evaluate}). Lo calcula el
 * backend para que el cliente no tenga que adivinar el motivo a partir de {@code xpAwarded == 0}.
 */
public enum FocusXpStatus {
    /** Ha dado XP (puede ser parcial si el tope del día se alcanza con este registro). */
    AWARDED,
    /** Habría dado XP, pero ya se alcanzó el tope diario de Pomodoro. */
    DAILY_CAP_REACHED,
    /** No da XP: descanso, fase sin completar, fecha pasada o menos de un ciclo mínimo de concentración. */
    NOT_ELIGIBLE
}
