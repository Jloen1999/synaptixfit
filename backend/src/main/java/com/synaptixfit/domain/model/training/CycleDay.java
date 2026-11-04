package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.training.CycleDayOutOfRangeException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.LocalDate;
import java.time.Instant;
import java.util.EnumSet;
import java.util.Set;

/**
 * Un día apuntado del seguimiento del ciclo (opcional, ADR 0033): si hay regla, la energía y las molestias.
 * Son datos de salud: solo los ve su dueño y se borran con un toque.
 *
 * @param energy   energía del día (opcional)
 * @param symptoms molestias (puede estar vacío)
 * @param note     nota libre de hasta {@value #NOTE_MAX} caracteres (opcional)
 */
public record CycleDay(LocalDate date, boolean period, CycleEnergy energy, Set<CycleSymptom> symptoms, String note,
                       Instant updatedAt) {

    public static final int NOTE_MAX = 300;
    /** Hasta un año atrás: basta para ver varios ciclos y estimar su duración. */
    public static final int MAX_DAYS_BACK = 365;

    public CycleDay {
        Guard.notNull(date, "date");
        symptoms = symptoms == null || symptoms.isEmpty() ? Set.of() : Set.copyOf(EnumSet.copyOf(symptoms));
        note = note == null || note.isBlank() ? null : note.strip();
        if (note != null && note.length() > NOTE_MAX) {
            throw new FieldValidationException("note", "INVALID_LENGTH", "note length must be at most " + NOTE_MAX);
        }
    }

    /** No es del futuro ni de hace más de {@link #MAX_DAYS_BACK} días. */
    public void requireLoggableOn(LocalDate today) {
        if (date.isAfter(today) || date.isBefore(today.minusDays(MAX_DAYS_BACK))) {
            throw new CycleDayOutOfRangeException();
        }
    }

    /** Hay alguna molestia que pide un entreno más suave. */
    public boolean hasDiscomfort() {
        return !symptoms.isEmpty();
    }

    /** Pide un ajuste suave del entreno: energía baja o alguna molestia (con o sin regla). */
    public boolean asksForGentlerTraining() {
        return energy == CycleEnergy.LOW || hasDiscomfort();
    }
}
