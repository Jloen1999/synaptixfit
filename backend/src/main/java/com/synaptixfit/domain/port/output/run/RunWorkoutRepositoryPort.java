package com.synaptixfit.domain.port.output.run;

import com.synaptixfit.domain.model.run.PlannedRun;
import com.synaptixfit.domain.model.run.RunWorkout;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Entrenos de carrera por pasos ({@code entrenos_carrera}) y su vínculo con los eventos del calendario
 * ({@code eventos_entreno_carrera}).
 */
public interface RunWorkoutRepositoryPort {

    RunWorkout save(RunWorkout workout);

    Optional<RunWorkout> findOwned(UUID userId, UUID workoutId);

    /** Del más reciente al más antiguo. */
    List<RunWorkout> findAll(UUID userId);

    void delete(UUID userId, UUID workoutId);

    void linkEvent(UUID blockId, UUID workoutId, UUID userId);

    /** Entreno de carrera del evento, si el evento es del usuario y salió de «Poner en el calendario». */
    Optional<UUID> workoutOfEvent(UUID userId, UUID blockId);

    /** Eventos con entreno de carrera aún por hacer que empiezan en [from, to), del primero al último. */
    List<PlannedRun> findPlanned(UUID userId, Instant from, Instant to);
}
