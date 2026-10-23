package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.util.UUID;

/** Empieza una sesión de un día de rutina o libre (ambos ids nulos). Si ya hay una en curso para ese día, la devuelve. */
public interface StartTrainingSessionUseCase {

    TrainingSession start(UUID userId, UUID routineId, UUID dayId);
}
