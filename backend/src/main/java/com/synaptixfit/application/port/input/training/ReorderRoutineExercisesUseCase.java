package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.List;
import java.util.UUID;

/** Reordena los ejercicios de un día. */
public interface ReorderRoutineExercisesUseCase {

    Routine reorder(UUID userId, UUID routineId, UUID dayId, List<UUID> orderedPlannedExerciseIds);
}
