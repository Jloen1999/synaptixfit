package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.ListSessionCalibrationsUseCase;
import com.synaptixfit.domain.model.training.load.CalibrationAnswer;
import com.synaptixfit.domain.model.training.load.CalibrationStep;
import com.synaptixfit.domain.model.training.load.ExerciseCalibrationRecord;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** DTOs de la calibración del peso en la primera sesión de cada ejercicio (ADR 0054). */
public final class CalibrationDtos {

    private CalibrationDtos() {
    }

    /**
     * Ejercicio de la sesión que se calibra. {@code answer}, {@code setNumber}, {@code step} y {@code nextWeightKg} son
     * nulos hasta que se responde la pregunta.
     */
    public record CalibrationTargetResponse(UUID plannedExerciseId, UUID exerciseId, CalibrationAnswer answer,
                                            Integer setNumber, CalibrationStep step, Double nextWeightKg) {
        public static CalibrationTargetResponse from(ListSessionCalibrationsUseCase.Target t) {
            return new CalibrationTargetResponse(t.plannedExerciseId(), t.exerciseId(), t.answer(), t.setNumber(),
                    t.step(), t.nextWeightKg());
        }

        public static CalibrationTargetResponse from(ExerciseCalibrationRecord r) {
            return new CalibrationTargetResponse(r.plannedExerciseId(), r.exerciseId(), r.answer(), r.setNumber(),
                    r.step(), r.nextWeightKg());
        }
    }

    /** Respuesta a «¿Cuántas más podrías haber hecho?» tras la serie {@code setNumber} (ya guardada) del hueco. */
    public record CalibrateRequest(@NotNull UUID plannedExerciseId, @NotNull @Min(1) @Max(50) Integer setNumber,
                                   @NotNull CalibrationAnswer answer) {
    }
}
