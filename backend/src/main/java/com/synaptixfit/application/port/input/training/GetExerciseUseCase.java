package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Exercise;
import java.util.UUID;

/** Detalle de un ejercicio activo. */
public interface GetExerciseUseCase {

    Exercise get(UUID exerciseId);
}
