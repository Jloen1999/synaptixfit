package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Registra (o sustituye) una serie de una sesión en curso. */
public interface RecordSessionSetUseCase {

    TrainingSession recordSet(Command command);

    record Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, Integer repsDone,
                   Double weightKg, boolean completed, int failedReps) {
    }
}
