package com.synaptixfit.application.port.input.run;

import com.synaptixfit.application.port.input.planner.BlockChange;
import java.time.Instant;
import java.util.UUID;

/**
 * «Poner en el calendario»: crea con el planificador un evento de tipo Entreno, con el nombre del entreno de
 * carrera y su duración prevista, y lo liga a él para que al grabarlo quede hecho.
 */
public interface ScheduleRunWorkoutUseCase {

    BlockChange scheduleWorkout(UUID userId, UUID workoutId, Instant start);
}
