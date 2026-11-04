package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.ExerciseNote;
import java.util.Optional;
import java.util.UUID;

/** Notas propias de cada persona sobre los ejercicios ({@code notas_ejercicio}). */
public interface ExerciseNoteRepositoryPort {

    Optional<ExerciseNote> find(UUID userId, UUID exerciseId);

    /** Crea o sustituye la nota de esa persona para ese ejercicio. */
    void save(UUID userId, ExerciseNote note);

    void delete(UUID userId, UUID exerciseId);
}
