package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** «Añadir ejercicio» en una sesión libre en curso (ADR 0067); si ya estaba, la sesión no cambia. */
public interface AddSessionExerciseUseCase {

    TrainingSession addExercise(UUID userId, UUID sessionId, UUID exerciseId);
}
