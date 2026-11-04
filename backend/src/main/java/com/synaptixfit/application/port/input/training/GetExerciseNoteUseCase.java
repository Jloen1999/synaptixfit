package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseNote;
import java.util.Optional;
import java.util.UUID;

/** Nota propia de la persona sobre un ejercicio, si la escribió. */
public interface GetExerciseNoteUseCase {

    Optional<ExerciseNote> note(UUID userId, UUID exerciseId);
}
