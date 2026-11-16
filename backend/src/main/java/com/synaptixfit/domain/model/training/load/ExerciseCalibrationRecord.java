package com.synaptixfit.domain.model.training.load;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.UUID;

/**
 * Respuesta de calibración guardada (tabla {@code calibraciones_ejercicio}, ADR 0054): una por ejercicio y sesión,
 * con el peso de la serie y el que se propuso después. Entra en la exportación de datos de la persona.
 */
public record ExerciseCalibrationRecord(UUID id, UUID userId, UUID sessionId, UUID plannedExerciseId,
                                        UUID exerciseId, int setNumber, CalibrationAnswer answer, Double weightKg,
                                        CalibrationStep step, Double nextWeightKg, Instant answeredAt) {

    public ExerciseCalibrationRecord {
        Guard.notNull(id, "id");
        Guard.notNull(userId, "userId");
        Guard.notNull(sessionId, "sessionId");
        Guard.notNull(exerciseId, "exerciseId");
        Guard.notNull(answer, "answer");
        Guard.notNull(step, "step");
        Guard.range(setNumber, "setNumber", 1, 50);
    }
}
