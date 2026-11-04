package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseNote;
import java.util.Optional;
import java.util.UUID;

/** Guarda la nota propia sobre un ejercicio; un texto vacío la borra (y devuelve vacío). */
public interface SaveExerciseNoteUseCase {

    Optional<ExerciseNote> save(UUID userId, UUID exerciseId, String text);
}
