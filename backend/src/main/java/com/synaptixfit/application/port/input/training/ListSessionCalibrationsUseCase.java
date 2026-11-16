package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.load.CalibrationAnswer;
import com.synaptixfit.domain.model.training.load.CalibrationStep;
import java.util.List;
import java.util.UUID;

/**
 * Ejercicios de una sesión propia en curso que se calibran (primera vez con kilos, ADR 0054), con la respuesta si ya
 * se dio. Vacía en una sesión libre, terminada o abandonada.
 */
public interface ListSessionCalibrationsUseCase {

    /** Ejercicio que se calibra; {@code answer}, {@code step} y {@code nextWeightKg} nulos si aún no se respondió. */
    record Target(UUID plannedExerciseId, UUID exerciseId, CalibrationAnswer answer, Integer setNumber,
                  CalibrationStep step, Double nextWeightKg) {
    }

    List<Target> calibrations(UUID userId, UUID sessionId);
}
