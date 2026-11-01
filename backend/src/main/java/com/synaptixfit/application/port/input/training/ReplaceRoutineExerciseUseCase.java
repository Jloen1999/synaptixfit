package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/**
 * Sustituye el ejercicio de un hueco de la rutina por otro del catálogo, en la misma posición y con los
 * parámetros adaptados a cómo se mide el nuevo (ver {@code ExerciseParameters.adaptedTo}).
 */
public interface ReplaceRoutineExerciseUseCase {

    Routine replaceExercise(UUID userId, UUID routineId, UUID plannedExerciseId, UUID exerciseId);
}
