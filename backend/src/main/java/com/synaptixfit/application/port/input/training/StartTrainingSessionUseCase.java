package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingSession;
import java.time.Instant;
import java.util.UUID;

/** Empieza una sesión de un día de rutina o libre (ambos ids nulos). Si ya hay una en curso para ese día, la devuelve. */
public interface StartTrainingSessionUseCase {

    default TrainingSession start(UUID userId, UUID routineId, UUID dayId) {
        return start(userId, routineId, dayId, null);
    }

    /**
     * @param startedAt hora de inicio que debe llevar una sesión nueva; nula es «ahora». «Entrenamos juntos» la usa para
     *                  que todo el grupo empiece a la misma hora (ADR 0047). No cambia una sesión que ya estaba en curso.
     */
    TrainingSession start(UUID userId, UUID routineId, UUID dayId, Instant startedAt);
}
