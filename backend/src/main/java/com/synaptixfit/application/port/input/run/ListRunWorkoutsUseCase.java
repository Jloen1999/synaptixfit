package com.synaptixfit.application.port.input.run;

import com.synaptixfit.domain.model.run.RunWorkout;
import java.util.List;
import java.util.UUID;

/** «Tus entrenos de carrera», del más reciente al más antiguo. */
public interface ListRunWorkoutsUseCase {

    List<RunWorkout> listWorkouts(UUID userId);
}
