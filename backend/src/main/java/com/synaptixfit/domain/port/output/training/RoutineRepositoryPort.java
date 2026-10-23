package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia del agregado rutina (semanas, días y ejercicios planificados). */
public interface RoutineRepositoryPort {

    /** Rutina no eliminada con toda su estructura. */
    Optional<Routine> findById(UUID id);

    /** Guarda el agregado completo, sincronizando semanas, días y ejercicios. */
    Routine save(Routine routine);

    PageResult<Routine> findByOwner(UUID ownerId, RoutineStatus status, PageRequest page);

    List<Routine> findAllByOwner(UUID ownerId);

    /** La rutina activa más reciente del usuario. */
    Optional<Routine> findLatestActive(UUID ownerId);

    /**
     * Rutinas de otros usuarios visibles para {@code viewerId}: públicas, o de amigos si hay amistad
     * aceptada; nunca de autores con shadowban.
     */
    PageResult<VisibleRoutine> findCommunity(UUID viewerId, String text, TrainingGoal goal, PageRequest page);

    /** La rutina si el usuario es su dueño o puede verla según las reglas de la comunidad. */
    Optional<VisibleRoutine> findVisible(UUID routineId, UUID viewerId);
}
