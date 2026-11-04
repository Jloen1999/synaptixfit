package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Nota propia de una persona sobre un ejercicio («asiento en el 4, agarre ancho»). Solo la ve ella; sirve
 * para recordar cómo ajustó la máquina o qué le funcionó (ADR 0031).
 */
public record ExerciseNote(UUID exerciseId, String text, Instant updatedAt) {

    public static final int MAX_LENGTH = 500;

    public ExerciseNote {
        Objects.requireNonNull(exerciseId, "exerciseId");
        text = Guard.length(Guard.notBlank(text, "text").strip(), "text", 1, MAX_LENGTH);
        Objects.requireNonNull(updatedAt, "updatedAt");
    }
}
