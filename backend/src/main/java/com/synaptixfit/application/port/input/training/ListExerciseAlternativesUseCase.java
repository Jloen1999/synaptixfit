package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Exercise;
import java.util.List;
import java.util.UUID;

/** Ejercicios que pueden sustituir a otro (mismo músculo principal), del más parecido al menos. */
public interface ListExerciseAlternativesUseCase {

    List<Exercise> alternatives(UUID exerciseId);
}
