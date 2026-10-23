package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Exercise;
import java.util.UUID;

/** Activa o desactiva un ejercicio (los inactivos no se ofrecen a los usuarios). */
public interface SetExerciseActiveUseCase {

    Exercise setActive(UUID exerciseId, boolean active);
}
