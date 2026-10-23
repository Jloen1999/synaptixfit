package com.synaptixfit.domain.model.notification;

/** Qué recuerda un aviso del plan de recordatorios del móvil ({@link ReminderPlanner}). */
public enum ReminderKind {
    /** Repasos espaciados (SM-2) vencidos. */
    REVIEWS,
    /** Bloque de deporte del planificador a punto de empezar. */
    TRAINING,
    /** Bloque de estudio o repaso del planificador a punto de empezar. */
    STUDY
}
