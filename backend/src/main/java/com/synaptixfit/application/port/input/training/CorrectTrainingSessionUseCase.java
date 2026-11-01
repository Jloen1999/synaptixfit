package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Corrige el RPE y la duración de una sesión terminada (recalcula calorías y carga física). */
public interface CorrectTrainingSessionUseCase {

    TrainingSession correct(Command command);

    record Command(UUID userId, UUID sessionId, int rpe, int durationMinutes) {
    }
}
