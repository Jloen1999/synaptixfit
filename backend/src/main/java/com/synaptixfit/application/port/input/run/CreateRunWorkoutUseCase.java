package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.RunWorkout;
import java.util.List;
import java.util.UUID;

/** Crea un entreno de carrera (desde cero o desde una plantilla, ya con el nombre en el idioma de la persona). */
public interface CreateRunWorkoutUseCase {

    record Command(UUID userId, String name, String templateCode, List<RunWorkout.Group> groups) {
    }

    RunWorkout createWorkout(Command command);
}
