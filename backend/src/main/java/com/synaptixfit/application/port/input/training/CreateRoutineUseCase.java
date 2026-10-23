package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Crea una rutina completa (semanas, días y ejercicios). */
public interface CreateRoutineUseCase {

    Routine create(Command command);

    record Command(UUID userId, String name, String description, Visibility visibility, TrainingGoal goal,
                   LocalDate startDate, List<RoutineStructureInput.Week> weeks) {
    }
}
