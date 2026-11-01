package com.synaptixfit.domain.model.training;

/**
 * Sesión sin terminar con su nombre (rutina y día). {@code stale}: abandonada (abierta más de
 * {@link TrainingSession#STALE_AFTER}); hay que terminarla con lo registrado o descartarla.
 */
public record OpenTrainingSession(TrainingSession session, SessionLabel label, boolean stale) {
}
