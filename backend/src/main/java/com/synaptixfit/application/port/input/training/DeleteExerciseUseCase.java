package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Borra un ejercicio; si alguna rutina lo usa, solo lo desactiva. */
public interface DeleteExerciseUseCase {

    Result delete(UUID exerciseId);

    /** {@code deleted} si se borró; {@code deactivated} si estaba en uso y se desactivó. */
    record Result(boolean deleted, boolean deactivated) {
    }
}
