package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.time.LocalDate;
import java.util.UUID;

/** Edita los datos generales de una rutina propia (los campos nulos no cambian). */
public interface UpdateRoutineUseCase {

    Routine update(Command command);

    record Command(UUID userId, UUID routineId, String name, String description, Visibility visibility,
                   TrainingGoal goal, LocalDate startDate, boolean clearStartDate) {
    }
}
