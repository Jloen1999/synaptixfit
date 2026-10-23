package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Exercise;
import java.util.UUID;

/** Detalle de cualquier ejercicio (administración). */
public interface AdminGetExerciseUseCase {

    Exercise adminGet(UUID exerciseId);
}
