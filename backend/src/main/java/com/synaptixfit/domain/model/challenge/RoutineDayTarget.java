package com.synaptixfit.domain.model.challenge;

import java.util.UUID;

/**
 * Día de la rutina en curso al que se puede vincular una tarea de reto (ADR 0032). Foto de solo lectura de
 * Entrenamiento. {@code dayNumber}: día de la semana (1 = lunes); {@code dayName} nulo si no tiene nombre.
 *
 * <p>Regla: solo se ofrecen los días que se pueden entrenar (con ejercicios) y que siguen sin hacer ni
 * saltar; un día cerrado ya no completaría nada.
 */
public record RoutineDayTarget(UUID dayId, String routineName, int weekNumber, int dayNumber, String dayName,
                               boolean closed, boolean trainable) {

    public boolean linkable() {
        return trainable && !closed;
    }
}
