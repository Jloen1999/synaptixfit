package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.load.CalibrationAnswer;
import com.synaptixfit.domain.model.training.load.ExerciseCalibrationRecord;
import java.util.UUID;

/**
 * Responde «¿Cuántas más podrías haber hecho?» tras la primera serie de un ejercicio nuevo (ADR 0054): devuelve el
 * peso de la serie siguiente y lo deja en la rutina para los días que aún no se han hecho.
 */
public interface CalibrateExerciseUseCase {

    record Command(UUID userId, UUID sessionId, UUID plannedExerciseId, int setNumber, CalibrationAnswer answer) {
    }

    ExerciseCalibrationRecord calibrate(Command command);
}
