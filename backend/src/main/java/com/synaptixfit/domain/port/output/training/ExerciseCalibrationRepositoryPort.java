package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.load.ExerciseCalibrationRecord;
import java.util.List;
import java.util.UUID;

/** Respuestas de calibración de la primera sesión de cada ejercicio (ADR 0054). */
public interface ExerciseCalibrationRepositoryPort {

    /** Guarda la respuesta; si ya había una de ese ejercicio en esa sesión, la sustituye. */
    ExerciseCalibrationRecord save(ExerciseCalibrationRecord calibration);

    List<ExerciseCalibrationRecord> findBySession(UUID sessionId);
}
